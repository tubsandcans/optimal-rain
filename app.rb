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

      new_pump_id = Pump.insert(
        pin_number: params[:pin_number], cycle_start: params[:cycle_start]
      )
      Pump.first(id: new_pump_id).next_watering
      redirect to("/")
    end

    put "/:id" do
      pump = Pump.first(id: params[:id])
      ACTIVE_SCHEDULES[pump.pin_number]&.cancel
      pump.update(cycle_start: params[:cycle_start])
      pump.next_watering
      redirect to("/")
    end

    delete "/:id" do
      pump = Pump.first(id: params[:id])
      ACTIVE_SCHEDULES[pump.pin_number]&.cancel
      pump.delete
      redirect to("/")
    end
  end
end
