require "dry-container"
require "logger"
require "raspi-gpio"
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

  # Initialize container for global active pins
  PUMP = Dry::Container.new
  PUMP.register(
    :pins,
    ENV.fetch("GPIO_PINS", "17").split(" ").each_with_object({}) do |pin, pins|
      pin_number = pin.to_i
      gpio = if Sinatra::Application.environment == :test
        MockGPIO.new
      else
        begin
          pin = GPIO.new(pin_number)
          # This sleep prevents a GPIO race-condition. For more information:
          # https://github.com/jwhitehorn/pi_piper/issues/92#issue-359237382
          sleep(0.1)
          pin.set_mode(OUT)
          pin
        rescue Errno::ENOENT => _e
          puts "Could not access actual GPIO, using MockGPIO instead"
          MockGPIO.new
        end
      end
      pins[pin_number] = {gpio: gpio}
    end
  )

  PUMP_CALIBRATIONS = Set.new

  def self.app
    Rack::Builder.app do
      run App
    end
  end
end

begin
  require_relative "models/pump"
rescue => e
  puts "error loading pumps! (safely ignore if run from migration)"
  puts e.message
end
