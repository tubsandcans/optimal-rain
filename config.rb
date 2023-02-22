require "logger"
require_relative "app"
require_relative "models/pump"

Logger.class_eval { alias_method :write, :<< }
module TurnAndBurnRunner
  # Logging + config:
  ACCESS_LOGGER = Logger.new(File.join(File.dirname(File.expand_path(__FILE__)),
                                       "log", "access.log"))
  ERROR_LOGGER = File.new(File.join(File.dirname(File.expand_path(__FILE__)),
                                    "log", "error.log"), "a+")
  ERROR_LOGGER.sync = true

  ACTIVE_SCHEDULES = {}
  ACTIVE_PINS = {17 => GPIO.new(17)}

  Pump.all.map(&:next_watering)
  def self.app
    Rack::Builder.app do
      run App
    end
  end
end
