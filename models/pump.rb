require "raspi-gpio"
require "rufus-scheduler"
require_relative "./watering"

class OptimalRain::Pump < Sequel::Model(:pumps)
  plugin :defaults_setter, cache: true
  default_values[:rate] = 200
  # add_watering_event - schedules Pump.pin_number to send HIGH signal at start_time
  #  if start_time is in the future. Also schedules Pump.pin_number to send LOW signal
  #  at start_time + duration, after which the schedule for the watering is shut down
  #  and the next_watering function gets called again.
  def add_watering_event(start_time:, gallon_percentage: 0.05)
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
    next_watering_event.schedule_watering_event
    OptimalRain::ACTIVE_SCHEDULES[pin_number] = next_watering_event
  end

  # next_watering - determines the next watering event for the current day.
  #   if there is an event, schedule it (add_watering_event) and return.
  #   if there is NOT an event, schedule to run the next day at light-on time.
  def next_watering(from: Time.now)
    if cycle_start > from
      add_watering_event(start_time: cycle_start + (5 * 24 * 60 * 60),
        gallon_percentage: 0.03)
      return
    end

    OptimalRain::ACCESS_LOGGER.info "Starting cycle for pin #{pin_number}"
    current_phase = OptimalRain::ACTIVE_PHASE_SET.find do |phase|
      phase.next_watering(pump: self, from: from)
    end
    unless current_phase
      OptimalRain::ACCESS_LOGGER.info "Cycle complete, done watering!"
      OptimalRain::ACTIVE_SCHEDULES[pin_number]&.cancel
    end
  end
end
