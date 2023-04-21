require "rufus-scheduler"
require_relative "./watering"

class OptimalRain::Pump < Sequel::Model(:pumps)
  plugin :defaults_setter, cache: true
  default_values[:rate] = 200
  default_values[:container_volume] = OptimalRain::ML_PER_GAL

  # add_watering_event - schedules Pump.pin_number to send HIGH signal at start_time
  #  if start_time is in the future. Also schedules Pump.pin_number to send LOW signal
  #  at start_time + duration, after which the schedule for the watering is shut down
  #  and the next_watering function gets called again.
  def add_watering_event(start_time:, gallon_percentage:)
    next_watering_event = OptimalRain::Watering.new(
      pump: self,
      start_time: start_time,
      scheduler: Rufus::Scheduler.new,
      volume_percentage: gallon_percentage
    )
    OptimalRain::ACCESS_LOGGER.info(
      "Schedule next watering to start at #{start_time}, and run for " \
      "#{next_watering_event.duration_in_seconds} seconds"
    )
    # schedule the watering event and save reference to it in ACTIVE_SCHEDULES
    next_watering_event.schedule_watering_events
    OptimalRain::PUMP[:pins][pin_number][:schedule] = next_watering_event
  end

  def active_phase(from: Time.now)
    OptimalRain::ACTIVE_PHASE_SET.find do |phase|
      phase.include?(time: from, start: cycle_start)
    end
  end

  # schedule_next_watering - schedules the first watering event after :from (if any):
  def schedule_next_watering(from: Time.now)
    # determine the active phase based on Pump.cycle_start and :from value, exit if none
    from = cycle_start if cycle_start > from
    phase = active_phase(from: from)
    if phase.nil?
      OptimalRain::ACCESS_LOGGER.info "Cycle complete, done watering!"
      return
    end

    next_event = phase.next_event(cycle_start: cycle_start, from: from)
    if next_event
      add_watering_event(start_time: next_event, gallon_percentage: phase.volume)
    end
  end

  # return all day's events that occur after pump's next watering event, if any:
  def events_for_day
    phase = active_phase
    if phase.nil?
      OptimalRain::ACCESS_LOGGER.info "Cycle complete, done watering!"
      return []
    end
    from = OptimalRain::PUMP[:pins][pin_number][:schedule]
             &.watering_event_start || Time.now
    phase.events_for_day(cycle_start: cycle_start, from: from)
  end
end
