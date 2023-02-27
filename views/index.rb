require "phlex"
require_relative "./layout"

class OptimalRain::Views::Index < Phlex::HTML
  def initialize(pumps:, new_pumps:)
    @pumps = pumps
    @new_pumps = new_pumps
  end

  def template
    render OptimalRain::Views::Layout.new do
      @new_pumps.each do |new_pump|
        h4 { "New cycle for pin #{new_pump}" }
        form(id: "new_cycle_form", method: "POST", action: "/") do
          label { "Cycle start-time" }
          input type: "hidden", name: "pin_number", value: new_pump
          input class: "cycle-start", type: "text", name: "cycle_start"
          button type: "submit" do
            "Set Cycle"
          end
        end
      end
      @pumps.each do |pump|
        schedule = OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]
        if schedule.nil?
          p { "This cycle has ended, no future watering events." }
        else
          p do
            b { "Next watering:" }
            em do
              schedule.begin_watering_event.strftime("%B %d %I:%M %p") +
                " for #{schedule.duration_in_seconds.round} seconds"
            end
          end
        end
        form id: "cycle_form", method: "POST", action: "/#{pump.id}" do
          b { "Cycle Start" }
          input type: "hidden", name: "_method", value: "put"
          input class: "cycle-start", type: "text",
            name: "cycle_start", value: pump.cycle_start
          button type: "submit" do
            "Change Cycle"
          end
        end
        form id: "remove_cycle_#{pump.id}", method: "POST", action: "/#{pump.id}" do
          input type: "hidden", name: "_method", value: "delete"
          button class: "remove", type: "submit" do
            "Remove"
          end
        end
      end
    end
  end
end
