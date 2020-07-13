module DelayedJobHelpers
  def queued_castle_track_event_jobs
    Delayed::Job
      .all
      .map(&:payload_object)
      .select { |payload| payload.class == Castle::TrackEvent }
      .map(&:castle_event)
      .to_set
  end
end
