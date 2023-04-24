require "phlex"
require_relative "./layout"
require_relative "./pumps"
require_relative "./new_pumps"

class OptimalRain::Views::Index < Phlex::HTML
  def initialize(pumps:, new_pumps:)
    @pumps = pumps
    @new_pumps = new_pumps
  end

  def template
    render OptimalRain::Views::Layout.new do
      render OptimalRain::Views::Pumps.new(pumps: @pumps)
      render OptimalRain::Views::NewPumps.new(pumps: @new_pumps)
    end
  end
end
