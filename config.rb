require "logger"
require "sequel"
require_relative "app"

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
    def set_value(signal)
      @value = signal
    end

    def get_value
      @value
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
  PUMP_PIN = 17
  mock_gpio = {PUMP_PIN => MockGPIO.new}
  ACTIVE_PINS = if Sinatra::Application.environment == :test
    mock_gpio
  else
    begin
      {PUMP_PIN => GPIO.new(PUMP_PIN)}
    rescue Errno::ENOENT => _e
      mock_gpio
    end
  end

  def self.app
    Rack::Builder.app do
      run App
    end
  end
end
