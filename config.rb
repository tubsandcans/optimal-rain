require "logger"
require "sequel"
require_relative "./app"

if Sinatra::Application.environment == :test
  Sequel.connect("sqlite://optimal_rain_test.db")
else
  Sequel.connect("sqlite://optimal_rain.db")
end
require_relative "models/pump"
require_relative "models/watering"

Logger.class_eval { alias_method :write, :<< }

module OptimalRain
  # MockGPIO is necessary for running outside of raspberry-pi environment.
  class MockGPIO
    attr_accessor :value

    def set_value(value)
      @value = value
    end

    def set_mode(_direction) = true
  end

  # Logging + config:
  ACCESS_LOGGER = Logger.new(File.join(File.dirname(File.expand_path(__FILE__)),
    "log", "access.log"))
  ERROR_LOGGER = File.new(File.join(File.dirname(File.expand_path(__FILE__)),
    "log", "error.log"), "a+")
  ERROR_LOGGER.sync = true

  ACTIVE_SCHEDULES = {}
  PUMP_PINS = ENV.fetch("GPIO_PINS", "17").split(" ")
  ACTIVE_PINS = PUMP_PINS.each_with_object({}) do |pin, pins|
    pin_number = pin.to_i
    if Sinatra::Application.environment == :test
      pins[pin_number] = MockGPIO.new
    else
      begin
        pins[pin_number] = GPIO.new(pin_number)
        sleep(0.1)
        pins[pin_number].set_mode(OUT)
      rescue Errno::ENOENT => _e
        pins[pin_number] = MockGPIO.new
      end
    end
  end

  def self.app
    Rack::Builder.app do
      run App
    end
  end
end
