# frozen_string_literal: true

module OptimalRain
  class Watering
    attr_accessor :scheduler, :pump

    def initialize(pump:, start_time:, scheduler:, volume_percentage:)
      @pump = pump
      @start_time = start_time
      @volume_percentage = volume_percentage
      @scheduler = scheduler
    end

    # schedule_watering_events - schedules on+off events and returns on-event start-time
    def schedule_watering_events
      if @scheduler.jobs.empty?
        begin
          set_schedule
        rescue Rufus::Scheduler::NotRunningError => _e
          @schedule = Rufus::Scheduler.new
          set_schedule
        end
      end
      @scheduler.jobs.first&.original
    end

    def watering_event_start
      @scheduler.jobs.first&.original
    end

    def duration_in_seconds
      (volume_in_ml.to_f / @pump.rate) * CALIBRATION_DURATION
    end

    def volume_in_ml
      (@volume_percentage * @pump.container_volume).round
    end

    def cancel
      @scheduler.jobs.map { @scheduler.unschedule(_1) }
      OptimalRain::NEXT_WATERING[:pins].delete(pump.pin_number)
    end

    private

    # set_schedule schedules pump 'on' and 'off' events. Off-event callback executes
    # past the off-signal to restart the scheduling of future watering events.
    def set_schedule
      gpio_pin = OptimalRain::PUMP[:pins][@pump.pin_number]
      @scheduler.at @start_time do
        gpio_pin.set_value(HIGH)
      end
      @scheduler.at(@start_time + duration_in_seconds) do
        gpio_pin.set_value(LOW)
        @scheduler.shutdown
        @pump.schedule_next_watering
      end
    end
  end
end
