module Castle
  # Class for tracking events to Castle /track endpoint
  class TrackEvent
    attr_reader :castle_event
    ALLOWED_TRAITS = %w[
      email
      created_at
      updated_at
    ].freeze

    def initialize(user, context, castle_event)
      @user = user
      @context = context
      @castle_event = castle_event
    end

    def perform
      Client.new(@context).track(track_params)
    end

    private

    def track_params
      {
        event: @castle_event,
        user_id: user_id,
        user_traits: user_traits
      }
    end

    def user_traits
      return {} if @user.nil?
      ALLOWED_TRAITS.each_with_object({}) do |trait, traits|
        if trait == "created_at"
          traits["registered_at"] = @user.attributes[trait]
        else
          traits[trait] = @user.attributes[trait]
        end
      end
    end

    def user_id
      @user&.id ? @user.id : false
    end
  end
end
