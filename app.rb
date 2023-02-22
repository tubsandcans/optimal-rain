require "raspi-gpio"
require "rufus-scheduler"
require "sinatra"
require "sequel"

class App < Sinatra::Application
  get "/" do
    new_pumps = TurnAndBurnRunner::ACTIVE_PINS.keys - Pump.all.map(&:pin_number)
    haml :index, locals: {pumps: Pump.all, new_pumps: new_pumps}
  end

  post "/" do
    Pump.insert(pin_number: params[:pin_number], cycle_start: params[:cycle_start])
    redirect to("/")
  end

  put "/:id" do
    pump = Pump.where(id: params[:id]).first
    TurnAndBurnRunner::ACTIVE_SCHEDULES[pump.pin_number]&.shutdown
    pump.update(cycle_start: params[:cycle_start])
    redirect to("/")
  end

  delete "/:id" do
    pump = Pump.where(id: params[:id]).first
    TurnAndBurnRunner::ACTIVE_SCHEDULES[pump.pin_number]&.shutdown
    pump.delete
    redirect to("/")
  end
end

__END__

@@ layout
%html
  != yield
