require "raspi-gpio"
require "rufus-scheduler"

class TurnAndBurnRunner::Pump < Sequel::Model(:pumps)
  # add_watering_event - schedules Pump.pin_number to send HIGH signal at start_time
  #  if start_time is in the future. Also schedules Pump.pin_number to send LOW signal
  #  at start_time + duration, after which the schedule for the watering is shut down
  #  and the next_watering function gets called again.
  def add_watering_event(start_time:, gallon_percentage: 0.05)
    return false if start_time < Time.now

    duration_in_seconds = (gallon_percentage / 4) * 60 * 60
    TurnAndBurnRunner::ACCESS_LOGGER.info(
      "Schedule next watering to start at #{start_time}, and run for " \
      "#{duration_in_seconds} seconds"
    )
    next_watering_event = TurnAndBurnRunner::Watering.new(
      pump: self,
      gpio_pin: TurnAndBurnRunner::ACTIVE_PINS[pin_number],
      start_time: start_time,
      scheduler: Rufus::Scheduler.new,
      volume_percentage: gallon_percentage
    )
    next_watering_event.begin_watering_event
    TurnAndBurnRunner::ACTIVE_SCHEDULES[pin_number] = next_watering_event
  end

  # next_watering - determines the next watering event for the current day.
  #   if there is an event, schedule it (add_watering_event) and return.
  #   if there is NOT an event, schedule to run the next day at light-on time.
  def next_watering
    TurnAndBurnRunner::ACCESS_LOGGER.info "Starting cycle for pin #{pin_number}"
    TurnAndBurnRunner::ACTIVE_PINS[pin_number].set_mode(OUT)
    days_elapsed = (Time.now - cycle_start).to_i / (24 * 60 * 60)
    new_time = cycle_start.dup
    new_time += days_elapsed * (24 * 60 * 60)
    case Time.now
    when cycle_start..(cycle_start + (5 * 24 * 60 * 60))
      # schedule the first watering of the cycle if current time
      # is before the first day of watering:
      add_watering_event(start_time: cycle_start + (5 * 24 * 60 * 60),
        gallon_percentage: 0.03)
      return
    when (cycle_start + (5 * 24 * 60 * 60))..(cycle_start + (10 * 24 * 60 * 60))
      # Second-half of veg phase, days 5-10
      4.times do
        return if add_watering_event(start_time: new_time, gallon_percentage: 0.03)
        new_time += (20 * 60)
      end
    when (cycle_start + (11 * 24 * 60 * 60))..(cycle_start + (20 * 24 * 60 * 60))
      # Early bloom phase, days 11-20 (1-10)
      new_time += (2 * 60 * 60)
      7.times do
        return if add_watering_event(start_time: new_time)
        new_time += (20 * 60)
      end
    when (cycle_start + (21 * 24 * 60 * 60))..(cycle_start + (30 * 24 * 60 * 60))
      # Bulking P1, days 21-30 (11-20)
      new_time += (60 * 60)
      4.times do
        return if add_watering_event(start_time: new_time)
        new_time += (20 * 60)
      end
      new_time += (5 * 60 * 60)
      2.times do
        return if add_watering_event(start_time: new_time)
        new_time += (4 * 60 * 60)
      end
    when (cycle_start + (31 * 24 * 60 * 60))..(cycle_start + (52 * 24 * 60 * 60))
      # Bulking P2, days 31-52 (21-42)
      new_time += (120 * 60)
      4.times do
        return if add_watering_event(start_time: new_time)
        new_time += (20 * 60)
      end
      new_time += (150 * 60)
      4.times do
        return if add_watering_event(start_time: new_time)
        new_time += (150 * 60)
      end
    when (cycle_start + (53 * 24 * 60 * 60))..(cycle_start + (63 * 24 * 60 * 60))
      # Late Bloom P1+P2, days 53-63 (P1:43-49, P2:50-53)
      new_time += (120 * 60)
      7.times do
        return if add_watering_event(start_time: new_time)
        new_time += (20 * 60)
      end
    when ((cycle_start + (64 * 24 * 60 * 60))..
      (cycle_start + (64 * 24 * 60 * 60) + (23 * 60 * 60)))
      # Flush, day 64 (54)
      new_time += (120 * 60)
      15.times do
        return if add_watering_event(start_time: new_time)
        new_time += (20 * 60)
      end
    else
      TurnAndBurnRunner::ACTIVE_SCHEDULES[pin_number].cancel
      TurnAndBurnRunner::ACCESS_LOGGER.info "Cycle complete, done watering!"
      return
    end

    # no watering event was added, check again tomorrow at light-on time:
    tomorrow_light_on = cycle_start + ((days_elapsed + 1) * 24 * 60 * 60)
    TurnAndBurnRunner::ACCESS_LOGGER.info "Going to check if tomorrow " \
      "(#{tomorrow_light_on}) has any watering events"
    try_tomorrow = Rufus::Scheduler.new
    try_tomorrow.at(tomorrow_light_on) do
      next_watering
    end
    TurnAndBurnRunner::ACTIVE_SCHEDULES[pin_number] = try_tomorrow
  end
end
