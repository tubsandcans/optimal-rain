require "sinatra"
require_relative "views/index"

module OptimalRain
  class App < Sinatra::Application
    get "/" do
      new_pumps = ACTIVE_PINS.keys - Pump.all.map(&:pin_number)
      Views::Index.new(pumps: Pump.all, new_pumps: new_pumps).call
    end

    post "/" do
      redirect to("/") if params[:cycle_start].empty?
      new_pump = Pump.new(
        pin_number: params[:pin_number], cycle_start: params[:cycle_start]
      )
      new_pump.rate # needed to cache 'rate' default-value before saving
      new_pump.container_volume # also for 'container_volume' default value
      new_pump.save_changes
      new_pump.schedule_next_watering
      redirect to("/")
    end

    put "/:id" do
      pump = Pump.first(id: params[:id])
      ACTIVE_SCHEDULES[pump.pin_number]&.cancel
      pump.update(**(%i[cycle_start rate container_volume]
                       .each_with_object({}) do |param_name, sanitized|
                       sanitized[param_name] = params[param_name]
                     end))
      pump.schedule_next_watering
      redirect to("/")
    end

    delete "/:id" do
      pump = Pump.first(id: params[:id])
      ACTIVE_SCHEDULES[pump.pin_number]&.cancel
      pump.delete
      redirect to("/")
    end

    get "/:id/calibrate" do
      pump = Pump.first(id: params[:id])
      gpio_pin = OptimalRain::ACTIVE_PINS[pump.pin_number]
      gpio_pin.set_value(HIGH)
      calibration = Rufus::Scheduler.new
      OptimalRain::PUMP_CALIBRATIONS << pump.pin_number
      calibration.in("#{OptimalRain::CALIBRATION_DURATION}s") do
        OptimalRain::PUMP_CALIBRATIONS.delete(pump.pin_number)
        gpio_pin.set_value(LOW)
      end
      redirect to("/")
    end
  end
end
