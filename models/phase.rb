require "dry-struct"
require "dry-types"

module Types
  include Dry.Types
end

module OptimalRain
  HOUR = 60 * 60
  DAY = 24 * HOUR

  class Phase < Dry::Struct
    include Types
    attribute :name, Types::Strict::String.meta(info: "phase name")
    attribute :duration, Types::Strict::Integer.meta(info: "phase-length in days")
    attribute :volume, Types::Strict::Float.default(0.05).meta(
      info: "volume watering amount per plant, expressed as a percentage " \
            "of container size"
    )
    attribute :replenishment_events, Types::Strict::Integer.default(0).meta(
      info: "number of replenishment watering events"
    )
    attribute :replenishment_offset,
      Types::Strict::Integer.default(2 * OptimalRain::HOUR).meta(
        info: "the number of seconds after cycle-start this phase begins"
      )
    attribute :replenishment_interval, Types::Strict::Integer.default(20 * 60).meta(
      info: "time in between replenishment watering events"
    )
    attribute :refreshment_events, Types::Strict::Integer.default(0).meta(
      info: "number of refreshment watering events"
    )
    attribute :refreshment_offset, Types::Strict::Integer.default(0).meta(
      info: "how long after last replenishment watering until first refreshment watering"
    )
    attribute :refreshment_interval, Types::Strict::Integer.default(0).meta(
      info: "time in between refreshment watering events"
    )

    # include? - determines if this phase is inclusive of :time based on :cycle_start
    def include?(cycle_start:, time: ::Time.now)
      adjusted_start = start(cycle_start: cycle_start)
      (adjusted_start..(adjusted_start + duration)).cover? time
    end

    # return the next watering event's start-time (after :from)
    def next_event(cycle_start:, from:)
      # if phase has no events, next watering event must be in next phase.
      if (replenishment_events + refreshment_events).zero?
        return OptimalRain::
            ACTIVE_PHASE_SET[OptimalRain::ACTIVE_PHASE_SET.index(self) + 1]
            .next_event(cycle_start: cycle_start, from: from)
      end
      start_time = calculate_start_time(cycle_start: cycle_start, from: from)
      return start_time if start_time

      # Active watering phase has no future or current watering event for today.
      # make recursive call with :from set to tomorrow's light-on time:
      next_event(
        cycle_start: cycle_start,
        from: start(cycle_start: cycle_start, from: from + OptimalRain::DAY)
      )
    end

    # returns all watering event times for :from day to occur after :from time
    def events_for_day(cycle_start:, from:)
      replenishment_events.times.collect do |iter|
        start(cycle_start: cycle_start, from: from) + replenishment_offset +
          (iter * replenishment_interval)
      end.concat(
        refreshment_events.times.collect do |iter|
          start(cycle_start: cycle_start, from: from) + refreshment_offset +
            (iter * refreshment_interval)
        end
      ).filter { _1 > from }
    end

    private

    def calculate_start_time(cycle_start:, from:)
      %w[replenishment refreshment].each do |prefix|
        first_watering_event = start(cycle_start: cycle_start, from: from) +
          send("#{prefix}_offset")
        send("#{prefix}_events").times do |iter|
          event = first_watering_event + (iter * send("#{prefix}_interval"))
          return event if event >= from
        end
      end
      nil
    end

    # calculate this phase's start:
    def start(cycle_start:, from: nil)
      offset = cycle_start + OptimalRain::ACTIVE_PHASE_SET.reduce(0) do |off, phase|
                               break off if phase.name == name
                               off + phase.duration
                             end
      if from
        day_offset = ((from - offset) / OptimalRain::DAY).to_i * OptimalRain::DAY
        offset += day_offset if day_offset > 0
      end

      offset
    end
  end
end
