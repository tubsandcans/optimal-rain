# frozen_string_literal: true

class OptimalRain::Views::Pumps < Phlex::HTML
  def initialize(pumps:)
    @pumps = pumps
  end

  def template
    @pumps.each do |pump|
      volume = (pump.container_volume / OptimalRain::ML_PER_GAL).to_i
      schedule = OptimalRain::PUMP[:pins][pump.pin_number][:schedule]
      other_waterings = pump.events_for_day.collect { _1.strftime("%I:%M %p") }.join(", ")
      if schedule.nil?
        p { "This cycle has ended, no future watering events." }
      elsif schedule.watering_event_start
        div "x-data": "{ open: false }", style: "margin-bottom:1.0rem" do
          a href: "#", "x-on:click.prevent": "open = !open" do
            b(class: "mr-1") { "Next watering:" }
          end
          em do
            schedule.watering_event_start.strftime("%B %d %I:%M %p") +
              " for #{schedule.duration_in_seconds.round} seconds " \
                "(#{schedule.volume_in_ml}ml)"
          end
          div "x-show": "open" do
            unless other_waterings.empty?
              plain(pump.events_for_day.collect { _1.strftime("%I:%M %p") }.join(", "))
            end
          end
        end
        div "x-data": "{ open: false }", style: "margin-bottom:1.0rem" do
          a href: "#", "x-on:click.prevent": "open = !open" do
            b(class: "mr-1") { "Current phase:" }
          end
          em { pump.active_phase&.name || "None" }
          div "x-show": "open" do
            OptimalRain::ACTIVE_PHASE_SET&.each do |phase|
              div style: "margin-top: 0.5rem" do
                if phase.include?(cycle_start: pump.cycle_start)
                  day = 1 + ((Time.now - pump.cycle_start) / OptimalRain::DAY).floor
                  b { "#{phase.name}, day #{day}" }
                else
                  plain(phase.name)
                end
              end
            end
            "expanded content showing phase and cycle data"
          end
        end
      end
      form id: "pump_#{pump.id}_cycle_form", method: "POST", action: "/#{pump.id}" do
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
  end
end
