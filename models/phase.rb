module OptimalRain
  # replenishment_events: number of replenishment watering events
  # replenishment_interval: time in between replenishment watering events
  # phase_start_offset: the number of seconds after cycle-start this phase begins
  # replenishment_offset (assume 0 if not set):
  #   the number of seconds after light-on until first watering
  # refreshment_events: number of refreshment watering events
  # refreshment_interval: time in between refreshment watering events
  # refreshment_offset:
  #   how long after last replenishment watering until first refreshment watering

  class Phase
    def initialize(name:, duration:, volume: 0.05, phase_start_offset: 0,
      replenishment_events: 0, replenishment_offset: (2 * 60 * 60),
      replenishment_interval: (20 * 60), refreshment_offset: 0,
      refreshment_interval: 0, refreshment_events: 0)
      @name = name
      @duration = duration
      @volume = volume
      @phase_start_offset = phase_start_offset
      @events = {replenishment_offset: replenishment_offset,
                 replenishment_interval: replenishment_interval,
                 replenishment_events: replenishment_events,
                 refreshment_offset: refreshment_offset,
                 refreshment_interval: refreshment_interval,
                 refreshment_events: refreshment_events}
    end

    # next_watering -
    def next_watering(pump:, from:)
      phase_start = pump.cycle_start + @phase_start_offset
      return false unless (phase_start..(phase_start + @duration)).cover? from

      # if phase has no events, next watering will always be next phase's
      # the last phase in a phase-set should ALWAYS have at least one event
      if (@events[:replenishment_events] + @events[:refreshment_events]).zero?
        phase_index = ACTIVE_PHASE_SET.index { _1 == self }
        return ACTIVE_PHASE_SET[phase_index + 1].next_watering(
          pump: pump, from: (pump.cycle_start + (@duration + OptimalRain::DAY))
        )
      end
      day_offset = ((from - (pump.cycle_start + @phase_start_offset)) /
        OptimalRain::DAY).to_i
      first_watering_event = pump.cycle_start + @phase_start_offset +
        @events[:replenishment_offset] + (day_offset * OptimalRain::DAY)
      next_event = nil
      @events[:replenishment_events].times do |iter|
        next_event = first_watering_event + (iter * @events[:replenishment_interval])
        if next_event >= from
          return pump.add_watering_event(start_time: next_event,
            gallon_percentage: @volume)
        end
      end

      first_watering_event = pump.cycle_start + @phase_start_offset +
        @events[:refreshment_offset] + (day_offset * OptimalRain::DAY)
      @events[:refreshment_events].times do |iter|
        next_event = first_watering_event + (iter * @events[:refreshment_interval])
        if next_event >= from
          return pump.add_watering_event(start_time: next_event,
            gallon_percentage: @volume)
        end
      end

      return false unless next_event

      # if next_event is in the past, call next_watering function with
      # :from set to light-on time of the next 24-hour period (tomorrow):
      if next_event < from
        next_watering(
          pump: pump,
          from: (pump.cycle_start + @phase_start_offset +
            ((day_offset + 1) * OptimalRain::DAY))
        )
      end
    end
  end
end
