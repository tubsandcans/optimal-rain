# frozen_string_literal: true

class OptimalRain::Watering
  attr_accessor :scheduler

  def initialize(pump:, start_time:, scheduler:, volume_percentage:, volume: 1)
    @pump = pump
    @start_time = start_time
    @volume_percentage = volume_percentage
    @scheduler = scheduler
    @volume = volume
  end

  def begin_watering_event
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

  # getter for stop event, scheduler.jobs can contain either 0 or 2 events
  def end_watering_event
    @scheduler.jobs.last&.original
  end

  def duration_in_seconds
    # rate per plant is 4GPH
    ((@volume_percentage * @volume) / 4) * 60 * 60
  end

  def volume_in_ml
    (@volume_percentage * @volume * 3785.41).round
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
      @pump.next_watering
    end
  end
end
