require_relative "./config"
require_relative "models/pump"

before {
  env["rack.errors"] = TurnAndBurnRunner::ERROR_LOGGER
}
use ::Rack::CommonLogger, TurnAndBurnRunner::ACCESS_LOGGER
run TurnAndBurnRunner.app
TurnAndBurnRunner::Pump.all.map(&:next_watering)
