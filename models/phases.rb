require_relative "./phase"

module OptimalRain
  module Phases
    # the first constant declared in this module is the default phase-set
    BURN_AND_TURN_PHASES = [
      Phase.new(name: "Vegetative days 1-4", duration: (4 * 24 * 60 * 60)),
      Phase.new(
        name: "Vegetative days 5-10",
        duration: (6 * 24 * 60 * 60),
        phase_start_offset: (5 * 24 * 60 * 60),
        replenishment_events: 4,
        replenishment_offset: 0,
        volume: 0.03
      ),
      Phase.new(
        name: "Early bloom (days 1-10)",
        duration: (10 * 24 * 60 * 60),
        phase_start_offset: (11 * 24 * 60 * 60),
        replenishment_events: 7
      ),
      Phase.new(
        name: "Bulking P1 (bloom, days 11-20)",
        duration: (10 * 24 * 60 * 60),
        phase_start_offset: (21 * 24 * 60 * 60),
        replenishment_events: 4,
        replenishment_offset: (60 * 60),
        refreshment_events: 2,
        refreshment_interval: (4 * 60 * 60),
        refreshment_offset: (5 * 60 * 60)
      ),
      Phase.new(
        name: "Bulking P2 (bloom, days 21-42)",
        duration: (22 * 24 * 60 * 60),
        phase_start_offset: (31 * 24 * 60 * 60),
        replenishment_events: 4,
        refreshment_events: 4,
        refreshment_interval: (2.5 * 60 * 60),
        refreshment_offset: (2.5 * 60 * 60)
      ),
      Phase.new(
        name: "Late bloom P1+P2 (days 43-53)",
        duration: (10 * 24 * 60 * 60),
        phase_start_offset: (53 * 24 * 60 * 60),
        replenishment_events: 7
      ),
      Phase.new(
        name: "Flush (bloom, day 54-56)",
        duration: (1 * 24 * 60 * 60),
        phase_start_offset: (64 * 24 * 60 * 60),
        replenishment_events: 15
      )
    ]
  end
end
