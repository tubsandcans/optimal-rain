require_relative "./phase"

module OptimalRain
  # all known watering programs, the first in the list is the default program.
  PHASE_SETS = [
    ["burn-and-turn", [
      Phase.new(name: "Vegetative days 1-4", duration: 4 * DAY),
      Phase.new(
        name: "Vegetative days 5-10",
        duration: 6 * DAY,
        start_offset: 5 * DAY,
        replenishment_events: 4,
        replenishment_offset: 0,
        volume: 0.03
      ),
      Phase.new(
        name: "Early bloom (days 1-10)",
        duration: 10 * DAY,
        start_offset: 11 * DAY,
        replenishment_events: 7
      ),
      Phase.new(
        name: "Bulking P1 (bloom, days 11-20)",
        duration: 10 * DAY,
        start_offset: 21 * DAY,
        replenishment_events: 4,
        replenishment_offset: HOUR,
        refreshment_events: 2,
        refreshment_interval: 4 * HOUR,
        refreshment_offset: 5 * HOUR
      ),
      Phase.new(
        name: "Bulking P2 (bloom, days 21-42)",
        duration: 22 * DAY,
        start_offset: 31 * DAY,
        replenishment_events: 4,
        refreshment_events: 4,
        refreshment_interval: (2.5 * HOUR).to_i,
        refreshment_offset: (2.5 * HOUR).to_i
      ),
      Phase.new(
        name: "Late bloom P1+P2 (days 43-53)",
        duration: 10 * DAY,
        start_offset: 53 * DAY,
        replenishment_events: 7
      ),
      Phase.new(
        name: "Flush (bloom, day 54-56)",
        duration: 1 * DAY,
        start_offset: 64 * DAY,
        replenishment_events: 15
      )
    ]]
  ]
end
