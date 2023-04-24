# frozen_string_literal: true

class OptimalRain::Views::NewPumps < Phlex::HTML
  def initialize(pumps:)
    @pumps = pumps
  end

  def template
    @pumps.each do |new_pump|
      h4 { "New cycle for pin #{new_pump}" }
      form(id: "pin_#{new_pump}_cycle_form", method: "POST", action: "/") do
        input type: "hidden", name: "pin_number", value: new_pump
        b(class: "mr-1") { "Cycle start" }
        input(class: "cycle-start mr-1", type: "text", name: "cycle_start")
        div do
          b(class: "mr-1") { "Container volume" }
          select name: "container_volume" do
            3.times.each do |i|
              value = OptimalRain::ML_PER_GAL * (i + 1)
              option(value: value) do
                "#{i + 1} gallon"
              end
            end
          end
        end
        button(type: "submit") { "Set Cycle" }
      end
    end
  end
end
