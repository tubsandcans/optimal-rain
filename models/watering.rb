# frozen_string_literal: true

module OptimalRain
  ML_PER_GAL = 3785.41
  CALIBRATION_DURATION = 30 # seconds

  class Watering
    attr_accessor :scheduler

    def initialize(pump:, start_time:, scheduler:, volume_percentage:, volume: 1)
      @pump = pump
      @start_time = start_time
      @volume_percentage = volume_percentage
      @scheduler = scheduler
      @volume = volume
    end

    def schedule_watering_event
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
      (@volume_percentage * @volume * ML_PER_GAL).round
    end

    def cancel
      @scheduler.jobs.map { @scheduler.unschedule(_1) }
      OptimalRain::ACTIVE_SCHEDULES[@pump.pin_number] = nil
    end

    private

    def set_schedule
      gpio_pin = OptimalRain::ACTIVE_PINS[@pump.pin_number]
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
