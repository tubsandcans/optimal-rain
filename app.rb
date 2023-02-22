require "logger"
require "raspi-gpio"
require "rufus-scheduler"
require "sinatra"
require "sequel"

DB = Sequel.connect("sqlite://turn_and_burn.db")
# DB.create_table :pumps do
#   primary_key :id
#   Integer :pin_number, unique: true, null: false
#   DateTime :cycle_start, null: false
# end
# Logging + config:
Logger.class_eval { alias_method :write, :<< }
access_log = File.join(File.dirname(File.expand_path(__FILE__)), "log", "access.log")
ACCESS_LOGGER = Logger.new(access_log)
error_logger = File.new(File.join(File.dirname(File.expand_path(__FILE__)), "log", "error.log"), "a+")
error_logger.sync = true
before {
  env["rack.errors"] = error_logger
}
configure do
  use ::Rack::CommonLogger, ACCESS_LOGGER
  set :active_schedules, {}
end

class Pump < Sequel::Model(:pumps)
  def add_watering_event(start_time, gallon_percentage)
    return false if start_time < Time.now

    # rate per plant is 4GPH, 60seconds * 60minutes = 3600seconds in an hour
    duration_in_seconds = (gallon_percentage / 4) * 3600
    ACCESS_LOGGER.info "Schedule next watering to start at #{start_time}, and run for " \
      "#{duration_in_seconds} seconds"
    settings.active_schedules[pin_number] = Rufus::Scheduler.new
    settings.active_schedules[pin_number].at start_time do
      ACTIVE_PINS[pin_number].set_value(HIGH)
    end
    settings.active_schedules[pin_number].at(start_time + duration_in_seconds) do
      ACTIVE_PINS[pin_number].set_value(LOW)
      settings.active_schedules[pin_number].shutdown
    end
  end

  def next_watering
    ACCESS_LOGGER.info "Starting cycle for pin #{pin_number}"
    ACTIVE_PINS[pin_number].set_mode(OUT)
    days_elapsed = (Time.now - cycle_start).to_i / (24 * 60 * 60)
    new_time = cycle_start.dup
    new_time += days_elapsed * (24 * 60 * 60)
    case Time.now
    when (cycle_start + (5 * 24 * 3600))..(cycle_start + (10 * 24 * 3600))
      4.times do
        # add_watering_event should determine if the event is in the future and if
        # it is return true in addition to scheduling the callback. The callback
        # will run this function at the end to schedule the next timer event.
        break if add_watering_event(new_time, 0.03)
        new_time += (20 * 60)
      end
    when (cycle_start + (11 * 24 * 3600))..(cycle_start + (20 * 24 * 3600))
      new_time += (2 * 3600)
      7.times do
        break if add_watering_event(new_time, 0.05)
        new_time += (20 * 60)
      end
    when (cycle_start + (21 * 24 * 3600))..(cycle_start + (30 * 24 * 3600))
      new_time += 3600
      4.times do
        break if add_watering_event(new_time, 0.05)
        new_time += (20 * 60)
      end
      new_time += (5 * 3600)
      2.times do
        break if add_watering_event(new_time, 0.05)
        new_time += (4 * 3600)
      end
    when (cycle_start + (31 * 24 * 3600))..(cycle_start + (52 * 24 * 3600))
      new_time += (120 * 60)
      4.times do
        break if add_watering_event(new_time, 0.05)
        new_time += (20 * 60)
      end
      new_time += (150 * 60) # 2.5hours
      4.times do
        break if add_watering_event(new_time, 0.05)
        new_time += (150 * 60)
      end
    when (cycle_start + (53 * 24 * 3600))..(cycle_start + (63 * 24 * 3600))
      new_time += (120 * 60)
      7.times do
        break if add_watering_event(new_time, 0.05)
        new_time += (20 * 60)
      end
    when (cycle_start + (64 * 24 * 3600))..(cycle_start + (64 * 24 * 3600) + (23 * 3600))
      new_time += (120 * 60)
      15.times do
        break if add_watering_event(new_time, 0.05)
        new_time += (20 * 60)
      end
    else
      tomorrow_light_on = cycle_start + ((days_elapsed + 1) * 24 * 60 * 60)
      ACCESS_LOGGER.info "Going to check if tomorrow (#{tomorrow_light_on}) " \
        "has any watering events"
      try_tomorrow = Rufus::Scheduler.new
      try_tomorrow.at(tomorrow_light_on) do
        next_watering
      end
    end
  end
end

ACTIVE_PINS = {17 => GPIO.new(17)}.freeze
Pump.all.map(&:next_watering)

get "/" do
  new_pumps = ACTIVE_PINS.keys - Pump.all.map(&:pin_number)
  haml :index, locals: {pumps: Pump.all, new_pumps: new_pumps}
end

post "/" do
  Pump.insert(pin_number: params[:pin_number], cycle_start: params[:cycle_start])
  redirect to("/")
end

put "/:id" do
  pump = Pump.where(id: params[:id]).first
  settings.active_schedules[pump.pin_number]&.shutdown
  pump.update(cycle_start: params[:cycle_start])
  redirect to("/")
end

delete "/:id" do
  pump = Pump.where(id: params[:id]).first
  settings.active_schedules[pump.pin_number]&.shutdown
  pump.delete
  redirect to("/")
end

__END__

@@ layout
%html
  != yield
