require_relative "./phase"

module OptimalRain
  # all known watering programs, the first in the list is the default program.
  # RULES:
  #   The last phase in a phase-set should ALWAYS have at least one event.
  #   There should never be two consecutive phases with zero events.
  PHASE_SETS = [
    ["burn-and-turn", [
      Phase.new(name: "Vegetative (days 1-5)", duration: 5 * DAY),
      Phase.new(
        name: "Vegetative (days 6-10)",
        duration: 5 * DAY,
        replenishment_events: 4,
        replenishment_offset: 0,
        volume: 0.03
      ),
      Phase.new(
        name: "Early bloom (days 11-20)",
        duration: 10 * DAY,
        replenishment_events: 7
      ),
      Phase.new(
        name: "Bulking P1 (days 21-30)",
        duration: 10 * DAY,
        replenishment_events: 4,
        replenishment_offset: HOUR,
        refreshment_events: 2,
        refreshment_interval: 4 * HOUR,
        refreshment_offset: 5 * HOUR
      ),
      Phase.new(
        name: "Bulking P2 (days 31-52)",
        duration: 22 * DAY,
        replenishment_events: 4,
        refreshment_events: 4,
        refreshment_interval: (2.5 * HOUR).to_i,
        refreshment_offset: (2.5 * HOUR).to_i
      ),
      Phase.new(
        name: "Late bloom P1+P2 (days 53-63)",
        duration: 10 * DAY,
        replenishment_events: 7
      ),
      Phase.new(
        name: "Flush (day 64)",
        duration: 1 * DAY,
        replenishment_events: 15
      )
    ]]
  ]
end
