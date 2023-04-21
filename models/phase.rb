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
    def include?(time:, start:)
      adjusted_start = start
      adjusted_start += start_offset unless start_offset.zero?
      (adjusted_start..(adjusted_start + duration)).cover? time
    end

    def calculate_start_time(cycle_start:, from:)
      day_offset = ((from - (cycle_start + start_offset)) / OptimalRain::DAY).to_i
      %w[replenishment refreshment].each do |prefix|
        first_watering_event = cycle_start + start_offset + send("#{prefix}_offset")
        send("#{prefix}_events").times do |iter|
          event = first_watering_event + (iter * send("#{prefix}_interval"))
          event += (day_offset * OptimalRain::DAY) if day_offset > 0
          return event if event >= from
        end
      end
      nil
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
      day_offset = ((from - (cycle_start + start_offset)) / OptimalRain::DAY).to_i
      next_event(
        cycle_start: cycle_start,
        from: (cycle_start + start_offset + ((day_offset + 1) * OptimalRain::DAY))
      )
    end

    # returns all watering event times for :from day to occur after :from time
    def events_for_day(cycle_start:, from:)
      day_offset = ((from - (cycle_start + start_offset)) / OptimalRain::DAY).to_i
      replenishment_events.times.collect do |iter|
        cycle_start + start_offset + replenishment_offset +
          (day_offset * OptimalRain::DAY) + (iter * replenishment_interval)
      end.concat(
        refreshment_events.times.collect do |iter|
          cycle_start + start_offset + refreshment_offset +
            (day_offset * OptimalRain::DAY) + (iter * refreshment_interval)
        end
      ).filter { _1 > from }
    end

    private

    # calculate this phase's start relative to the start of its phase_set:
    def start_offset
      @offset ||= OptimalRain::ACTIVE_PHASE_SET.reduce(0) do |off, phase|
        break off if phase.name == name
        off + phase.duration
      end
    end
  end
end
