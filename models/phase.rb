require "dry-struct"
require "dry-types"

module Types
  include Dry.Types
end

module OptimalRain
  class Phase < Dry::Struct
    include Types
    attribute :name, Types::Strict::String.meta(info: "phase name")
    attribute :duration, Types::Strict::Integer.meta(info: "phase-length in days")
    attribute :volume, Types::Strict::Float.default(0.05).meta(
      info: "target-volume amount per watering per plant, expressed as a percentage " \
            "of 1gallon container size "
    )
    attribute :phase_start_offset, Types::Strict::Integer.default(0).meta(
      info: "number of seconds this phase begins after cycle-start"
    )
    attribute :replenishment_events, Types::Strict::Integer.default(0).meta(
      info: "number of replenishment watering events"
    )
    attribute :replenishment_offset, Types::Strict::Integer.default(2 * 60 * 60).meta(
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

    # next_watering -
    def next_watering(pump:, from:)
      phase_start = pump.cycle_start + phase_start_offset
      return false unless (phase_start..(phase_start + duration)).cover? from

      # if phase has no events, next watering will always be next phase's
      # the last phase in a phase-set should ALWAYS have at least one event
      if (replenishment_events + refreshment_events).zero?
        phase_index = ACTIVE_PHASE_SET.index { _1 == self }
        return ACTIVE_PHASE_SET[phase_index + 1].next_watering(
          pump: pump, from: (pump.cycle_start + (duration + OptimalRain::DAY))
        )
      end
      day_offset = ((from - (pump.cycle_start + phase_start_offset)) /
        OptimalRain::DAY).to_i
      first_watering_event = pump.cycle_start + phase_start_offset +
        replenishment_offset + (day_offset * OptimalRain::DAY)
      next_event = nil
      replenishment_events.times do |iter|
        next_event = first_watering_event + (iter * replenishment_interval)
        if next_event >= from
          return pump.add_watering_event(start_time: next_event,
            gallon_percentage: volume)
        end
      end

      first_watering_event = pump.cycle_start + phase_start_offset +
        refreshment_offset + (day_offset * OptimalRain::DAY)
      refreshment_events.times do |iter|
        next_event = first_watering_event + (iter * refreshment_interval)
        if next_event >= from
          return pump.add_watering_event(start_time: next_event,
            gallon_percentage: volume)
        end
      end

      return false unless next_event

      # if next_event is in the past, call next_watering function with
      # :from set to light-on time of the next 24-hour period (tomorrow):
      if next_event < from
        next_watering(
          pump: pump,
          from: (pump.cycle_start + phase_start_offset +
            ((day_offset + 1) * OptimalRain::DAY))
        )
      end
    end
  end
end
