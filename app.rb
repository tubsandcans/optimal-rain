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

      Pump.insert(pin_number: params[:pin_number], cycle_start: params[:cycle_start])
      Pump.last.next_watering
      redirect to("/")
    end

    put "/:id" do
      pump = Pump.where(id: params[:id]).first
      ACTIVE_SCHEDULES[pump.pin_number]&.cancel
      pump.update(cycle_start: params[:cycle_start])
      pump.next_watering
      redirect to("/")
    end

    delete "/:id" do
      pump = Pump.where(id: params[:id]).first
      ACTIVE_SCHEDULES[pump.pin_number]&.cancel
      pump.delete
      redirect to("/")
    end
  end
end
