require "sinatra"

module TurnAndBurnRunner
  class App < Sinatra::Application
    get "/" do
      new_pumps = ACTIVE_PINS.keys - Pump.all.map(&:pin_number)
      haml :index, locals: {pumps: Pump.all, new_pumps: new_pumps}
    end

    post "/" do
      Pump.insert(pin_number: params[:pin_number], cycle_start: params[:cycle_start])
      redirect to("/")
    end

    put "/:id" do
      pump = Pump.where(id: params[:id]).first
      ACTIVE_SCHEDULES[pump.pin_number]&.shutdown
      pump.update(cycle_start: params[:cycle_start])
      redirect to("/")
    end

    delete "/:id" do
      pump = Pump.where(id: params[:id]).first
      ACTIVE_SCHEDULES[pump.pin_number]&.shutdown
      pump.delete
      redirect to("/")
    end
  end
end

__END__

@@ layout
%html
  %head
    %meta{charset: "UTF-8"}
    %meta{"http-equiv": "X-UA-Compatible", content: "IE=edge"}
    %meta{name: "viewport", content: "width=device-width", "initial-scale": 1.0}
    %link{rel: "stylesheet", href: "https://cdn.simplecss.org/simple.min.css"}
    %link{rel: "stylesheet", href: "https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css"}
    %link{rel: "stylesheet", href: "main.css"}
    %script{src: "https://cdn.jsdelivr.net/npm/flatpickr"}
    %title Turn and Burn
  %body{onload: "flatpickr('.cycle-start', {enableTime: true});"}
    %header
      %h1 Turn and Burn runner
    %main
      != yield
