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
        volume = (pump.container_volume / OptimalRain::ML_PER_GAL).to_i
        schedule = OptimalRain::ACTIVE_SCHEDULES
          .resolve("schedules.find").call(pump.pin_number)
        if schedule.nil?
          p { "This cycle has ended, no future watering events." }
        elsif schedule.watering_event_start
          p do
            b(class: "mr-1") { "Next watering:" }
            em do
              schedule.watering_event_start.strftime("%B %d %I:%M %p") +
                " for #{schedule.duration_in_seconds.round} seconds " \
                "(#{schedule.volume_in_ml}ml)"
            end
          end
          div style: "margin-bottom:1.0rem" do
            b(class: "mr-1") { "Current phase:" }
            em { pump.active_phase.first&.name }
          end
        end
        form id: "cycle_form", method: "POST", action: "/#{pump.id}" do
          input type: "hidden", name: "_method", value: "put"
          b(class: "mr-1") { "Pin #{pump.pin_number} cycle start: " }
          plain(pump.cycle_start.strftime("%B %d %I:%M %p"))
          div style: "margin-top: 1.0rem" do
            b(class: "mr-1") { "Container volume: " }
            plain("#{volume} gallon" + ((volume > 1) ? "s" : ""))
          end
          div class: "inline" do
            div style: "margin-top: 0.5rem" do
              b(class: "mr-1") { "Rate" }
              input class: "mr-1", type: "text", name: "rate", value: pump.rate, style: "width: 120px"
            end
            div style: "margin-top: 1.8rem" do
              plain("ml-per-plant in 30 seconds")
            end
          end
          button(type: "submit") { "Change Rate" }
        end
        div class: "inline" do
          form class: "inline mr-2", id: "remove_cycle_#{pump.id}",
            method: "POST", action: "/#{pump.id}" do
            input type: "hidden", name: "_method", value: "delete"
            button(class: "remove", type: "submit") { "Remove" }
          end
          unless OptimalRain::PUMP_CALIBRATIONS.include? pump.pin_number
            form class: "inline", id: "calibrate_cycle_#{pump.id}",
              method: "GET", action: "/#{pump.id}/calibrate" do
              button(class: "calibrate", type: "submit") { "Calibrate" }
            end
          end
        end
      end
      @new_pumps.each do |new_pump|
        h4 { "New cycle for pin #{new_pump}" }
        form(id: "new_cycle_form", method: "POST", action: "/") do
          input type: "hidden", name: "pin_number", value: new_pump
          b(class: "mr-1") { "Cycle start" }
          input(class: "cycle-start mr-1", type: "text", name: "cycle_start")
          div do
            b(class: "mr-1") { "Container volume" }
            container_volume_select
          end
          button(type: "submit") { "Set Cycle" }
        end
      end
    end
  end

  private

  def container_volume_select
    select name: "container_volume" do
      3.times.each do |i|
        value = OptimalRain::ML_PER_GAL * (i + 1)
        option(value: value) do
          "#{i + 1} gallon"
        end
      end
    end
  end
end
