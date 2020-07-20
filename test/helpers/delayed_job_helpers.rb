module DelayedJobHelpers
  def queued_castle_track_event_jobs
    Delayed::Job
      .all
      .map(&:payload_object)
      .select { |payload| payload.class == Castle::TrackEvent }
      .map(&:castle_event)
      .to_set
  end

  def all_queued_job_classes
    Delayed::Job
      .all
      .map { |job| job.payload_object.class }
      .to_set
  end
end
