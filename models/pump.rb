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
    OptimalRain::ACTIVE_SCHEDULES[:schedules][pin_number] = next_watering_event
  end

  def active_phase(from: Time.now)
    phase_start_offset = 0
    OptimalRain::ACTIVE_PHASE_SET.find do |phase|
      phase.start_offset = phase_start_offset
      phase_start_offset += phase.duration
      phase.include?(time: from, start: cycle_start)
    end
  end

  # schedule_next_watering - schedules the first watering event after :from (if any):
  def schedule_next_watering(from: Time.now)
    from = cycle_start if cycle_start > from
    phase = active_phase(from: from) { from = _1 }
    if phase.nil?
      OptimalRain::ACCESS_LOGGER.info "Cycle complete, done watering!"
      return
    end

    # if phase has no events, next watering event must be in next phase.
    if (phase.replenishment_events + phase.refreshment_events).zero?
      offset = phase.start_offset + phase.duration
      phase = OptimalRain::
          ACTIVE_PHASE_SET[OptimalRain::ACTIVE_PHASE_SET.index(phase) + 1]
      phase.start_offset = offset
      from = cycle_start + offset
    end

    day_offset = ((from - (cycle_start + phase.start_offset)) / OptimalRain::DAY).to_i
    # go over all phase's watering events (replenishment+refreshment), schedule the
    # first one to occur after :from and return.
    return if %w[replenishment refreshment].any? do |prefix|
      first_watering_event = cycle_start + phase.start_offset +
        phase.send("#{prefix}_offset") + (day_offset * OptimalRain::DAY)
      phase.send("#{prefix}_events").times do |iter|
        next_event = first_watering_event + (iter * phase.send("#{prefix}_interval"))
        if next_event >= from
          add_watering_event(start_time: next_event, gallon_percentage: phase.volume)
          break true
        end
      end == true # event only got added if boolean true, not truthy-value
    end

    # Active watering phase has no future or current watering event for today.
    # make recursive call with :from set to tomorrow's light-on time:
    schedule_next_watering(from: (cycle_start + phase.start_offset +
        ((day_offset + 1) * OptimalRain::DAY)))
  end
end
