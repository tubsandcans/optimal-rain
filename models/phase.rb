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
      info: "target-volume amount per watering per plant, expressed as a percentage " \
            "of 1gallon container size "
    )
    attribute :start_offset, Types::Strict::Integer.default(0).meta(
      info: "number of seconds this phase begins after cycle-start"
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
  end
end
