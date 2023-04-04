require "dry-container"
require "logger"
require "sequel"
require_relative "./app"

if Sinatra::Application.environment == :test
  Sequel.connect("sqlite://optimal_rain_test.db")
else
  Sequel.connect("sqlite://optimal_rain.db")
end
require_relative "models/phase_sets"

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

  program_name = ENV.fetch("PROGRAM", PHASE_SETS.first.first)
  ACTIVE_PHASE_SET = PHASE_SETS.find { _1.first == program_name }&.last
  if ACTIVE_PHASE_SET.nil?
    puts "bad value provided for PROGRAM, no watering program found for '#{program_name}'"
    exit 9
  end

  ML_PER_GAL = 3785.41
  CALIBRATION_DURATION = 30 # seconds

  # Initialize container keeping active schedule state
  ACTIVE_SCHEDULES = Dry::Container.new
  ACTIVE_SCHEDULES.register(:schedules, [])
  ACTIVE_SCHEDULES.namespace("schedules") do
    register("find", call: false) do |pin_number|
      ACTIVE_SCHEDULES[:schedules].find { _1.pump.pin_number == pin_number }
    end
    register("delete", call: false) do |pin_number|
      ACTIVE_SCHEDULES[:schedules].delete_if { _1.pump.pin_number == pin_number }
    end
  end

  PUMP_CALIBRATIONS = Set.new
  PUMP_PINS = ENV.fetch("GPIO_PINS", "17").split(" ")
  ACTIVE_PINS = PUMP_PINS.each_with_object({}) do |pin, pins|
    pin_number = pin.to_i
    if Sinatra::Application.environment == :test
      pins[pin_number] = MockGPIO.new
    else
      begin
        pins[pin_number] = GPIO.new(pin_number)
        # This sleep prevents a GPIO race-condition. For more information:
        # https://github.com/jwhitehorn/pi_piper/issues/92#issue-359237382
        sleep(0.1)
        pins[pin_number].set_mode(OUT)
      rescue Errno::ENOENT => _e
        puts "Could not access actual GPIO, using MockGPIO instead"
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

require_relative "models/pump"
