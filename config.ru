require_relative "./config.rb"
require_relative "models/pump"

error_logger = TurnAndBurnRunner::ERROR_LOGGER
before {
  env["rack.errors"] = error_logger
}
use ::Rack::CommonLogger, TurnAndBurnRunner::ACCESS_LOGGER
set :error_logger, error_logger
run TurnAndBurnRunner.app
