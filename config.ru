require_relative "./config"
require_relative "models/pump"

before {
  env["rack.errors"] = OptimalRain::ERROR_LOGGER
}
use ::Rack::CommonLogger, OptimalRain::ACCESS_LOGGER
run OptimalRain.app
OptimalRain::Pump.all.map(&:next_watering)
