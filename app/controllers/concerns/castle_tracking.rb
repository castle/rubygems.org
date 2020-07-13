module CastleTracking
  extend ActiveSupport::Concern

  included do
    def track_castle_event(castle_event, user)
      context = ::Castle::Client.to_context(request)
      Delayed::Job.enqueue(
        Castle::TrackEvent.new(user, context, castle_event), priority: PRIORITIES[:stats]
      )
    end
  end
end
