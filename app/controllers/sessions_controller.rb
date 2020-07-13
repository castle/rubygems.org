class SessionsController < Clearance::SessionsController
  include CastleTracking

  def create
    @user = find_user

    if @user&.mfa_enabled?
      session[:mfa_user] = @user.handle
      track_castle_event(Castle::Events::CHALLENGE_REQUESTED, @user)
      render "sessions/otp_prompt"
    else
      do_login
    end
  end

  def mfa_create
    @user = User.find_by_name(session[:mfa_user])
    session.delete(:mfa_user)
    if @user&.mfa_enabled? && @user&.otp_verified?(params[:otp])
      track_castle_event(Castle::Events::CHALLENGE_SUCCEEDED, @user)
      do_login
    else
      track_castle_event(Castle::Events::CHALLENGE_FAILED, @user)
      login_failure(t("multifactor_auths.incorrect_otp"), @user)
      render template: "sessions/new", status: :unauthorized
    end
  end

  def destroy
    track_castle_event(Castle::Events::LOGOUT_SUCCEEDED, current_user)
    super
  end

  private

  def do_login
    sign_in(@user) do |status|
      if status.success?
        login_success
        redirect_back_or(url_after_create)
      else
        failed_user = User.find_by_name(session_params.dig(:who))
        login_failure(status.failure_message, failed_user)
        render template: "sessions/new", status: :unauthorized
      end
    end
  end

  def login_success
    StatsD.increment "login.success"
    track_castle_event(Castle::Events::LOGIN_SUCCEEDED, @user)
  end

  def login_failure(message, failed_user)
    StatsD.increment "login.failure"
    track_castle_event(Castle::Events::LOGIN_FAILED, failed_user)
    flash.now.notice = message
  end

  def find_user
    who = session_params[:who].is_a?(String) && session_params.fetch(:who)
    password = session_params[:password].is_a?(String) && session_params.fetch(:password)

    User.authenticate(who, password) if who && password
  end

  def url_after_create
    dashboard_path
  end

  def session_params
    params.require(:session).permit(:who, :password)
  end
end
