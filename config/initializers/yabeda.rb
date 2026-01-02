# frozen_string_literal: true

# Skip metrics in test/cypress environments
return if Rails.env.test? || Rails.env.cypress?

require "yabeda/prometheus"

Yabeda.configure do
  group :flyweight do
    gauge :pilots_total,
          comment: "Total number of registered pilots",
          tags:    []

    gauge :flights_active,
          comment: "Number of flights with date >= today",
          tags:    []
  end

  group :good_job do
    gauge :jobs_scheduled,
          comment: "Number of jobs scheduled (waiting to run)",
          tags:    []

    gauge :jobs_running,
          comment: "Number of jobs currently running",
          tags:    []

    gauge :jobs_finished,
          comment: "Number of finished jobs",
          tags:    []

    gauge :jobs_discarded,
          comment: "Number of discarded (failed) jobs",
          tags:    []
  end

  collect do
    flyweight.pilots_total.set({}, Pilot.count)
    flyweight.flights_active.set({}, Flight.where(date: Date.current..).count)

    good_job.jobs_scheduled.set({}, GoodJob::Job.scheduled.count)
    good_job.jobs_running.set({}, GoodJob::Job.running.count)
    good_job.jobs_finished.set({}, GoodJob::Job.finished.count)
    good_job.jobs_discarded.set({}, GoodJob::Job.discarded.count)
  end
end

Yabeda.configure!
