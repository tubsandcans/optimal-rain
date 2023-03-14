require "raspi-gpio"
require "rufus-scheduler"
require_relative "./watering"

class OptimalRain::Pump < Sequel::Model(:pumps)
  plugin :defaults_setter, cache: true
  default_values[:rate] = 200
  default_values[:container_volume] = 1 * OptimalRain::ML_PER_GAL

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
    next_watering_event.schedule_watering_event
    OptimalRain::ACTIVE_SCHEDULES[pin_number] = next_watering_event
  end

  # schedule_next_watering - schedules the first watering event to occur after :from (if any):
  def schedule_next_watering(from: Time.now)
    from = cycle_start if cycle_start > from
    OptimalRain::ACCESS_LOGGER.info "Starting cycle for pin #{pin_number}"
    OptimalRain::ACTIVE_PHASE_SET.each do |phase|
      phase_start = cycle_start + phase.start_offset
      next unless (phase_start..(phase_start + phase.duration)).cover? from

      # if phase has no events, next watering will always be next phase's
      # the last phase in a phase-set should ALWAYS have at least one event
      if (phase.replenishment_events + phase.refreshment_events).zero?
        phase_index = OptimalRain::ACTIVE_PHASE_SET.index { _1 == phase }
        phase = OptimalRain::ACTIVE_PHASE_SET[phase_index + 1]
        from = cycle_start + phase.start_offset
      end

      day_offset = ((from - (cycle_start + phase.start_offset)) /
        OptimalRain::DAY).to_i
      next_event = nil
      %w[replenishment refreshment].each do |prefix|
        first_watering_event = cycle_start + phase.start_offset +
          phase.send("#{prefix}_offset") + (day_offset * OptimalRain::DAY)
        phase.send("#{prefix}_events").times do |iter|
          next_event = first_watering_event + (iter * phase.send("#{prefix}_interval"))
          if next_event >= from
            return add_watering_event(start_time: next_event,
              gallon_percentage: phase.volume)
          end
        end
      end
      # if next_event is in the past, call next_watering function with
      # :from set to light-on time of the next 24-hour period (tomorrow):
      if next_event < from
        return schedule_next_watering(from: (cycle_start + phase.start_offset +
            ((day_offset + 1) * OptimalRain::DAY)))
      end
    end
    OptimalRain::ACCESS_LOGGER.info "Cycle complete, done watering!"
  end
end
