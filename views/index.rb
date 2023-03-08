require "phlex"
require_relative "./layout"

class OptimalRain::Views::Index < Phlex::HTML
  def initialize(pumps:, new_pumps:)
    @pumps = pumps
    @new_pumps = new_pumps
  end

  def template
    render OptimalRain::Views::Layout.new do
      @pumps.each do |pump|
        schedule = OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]
        if schedule.nil?
          p { "This cycle has ended, no future watering events." }
        else
          p do
            b(class: "mr-1") { "Next watering:" }
            em do
              schedule.begin_watering_event.strftime("%B %d %I:%M %p") +
                " for #{schedule.duration_in_seconds.round} seconds " \
                "(#{schedule.volume_in_ml}ml)"
            end
          end
        end
        form id: "cycle_form", method: "POST", action: "/#{pump.id}" do
          b(class: "mr-1") { "Pin #{pump.pin_number} cycle start" }
          input type: "hidden", name: "_method", value: "put"
          input class: "cycle-start mr-1", type: "text",
            name: "cycle_start", value: pump.cycle_start
          label { "(ml-per-plant in 30 seconds)" }
          b(class: "mr-1") { "Rate" }
          input class: "mr-1", type: "text", name: "rate", value: pump.rate
          button(type: "submit") { "Change Cycle" }
        end
        form id: "remove_cycle_#{pump.id}", method: "POST", action: "/#{pump.id}" do
          input type: "hidden", name: "_method", value: "delete"
          button(class: "remove", type: "submit") { "Remove" }
        end
        unless OptimalRain::PUMP_CALIBRATIONS.include? pump.pin_number
          form id: "calibrate_cycle_#{pump.id}", method: "GET", action: "/#{pump.id}/calibrate" do
            button(class: "calibrate", type: "submit") { "Calibrate" }
          end
        end
      end
      @new_pumps.each do |new_pump|
        h4 { "New cycle for pin #{new_pump}" }
        form(id: "new_cycle_form", method: "POST", action: "/") do
          label { "Cycle start-time" }
          input type: "hidden", name: "pin_number", value: new_pump
          input class: "cycle-start mr-1", type: "text", name: "cycle_start"
          button(type: "submit") { "Set Cycle" }
        end
      end
    end
  end
end
