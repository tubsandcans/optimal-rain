[![Ruby](https://github.com/tubsandcans/optimal-rain/actions/workflows/ruby.yml/badge.svg?branch=main)](https://github.com/tubsandcans/optimal-rain/actions/workflows/ruby.yml)

## Managed plant watering schedule with Raspberry Pi (and Sinatra)

### GPIO

Active pins can be set by environment variable `GPIO_PINS`.

- If `GPIO_PINS` is not present, pin 17 will be used as the one active pin.
- Multiple pump pins: `GPIO_PINS="17 18 19"`.
- Don't forget to add to the startup.sh script before deploying to a Raspberry pi.

### Setup

Make sure sqlite3, ruby, and bundler are installed

`bundle install`

`bundle exec rake db:migrate`

`APP_ENV=test bundle exec rake db:migrate`

To run in development on port 9292:

`bundle exec rackup`

### Run Checks

`bundle exec rake`

### Add crontab entry on Raspberry pi to always run at startup:

`crontab -u pi -e`

`@reboot sh /home/pi/optimal-rain/startup.sh`

### Using

- Accepts http connections on port 9292
- `bundle exec rackup` to start, or startup.sh script (runs with `APP_ENV=production`).
- Select a date and time from the form field and submit to create or modify a cycle.
- Cycle-start time should be the intended light-on time during the bloom phase.
- Watering volumes are calculated using a percentage of the selected container size.
- Watering time (how long pump is kept on) is determined by volume and pump flow-rate.

#### Calibrating

Once a pump is connected to the GPIO-controlled power and ready with a water source, 
create a pump in the application by selecting a start-date and time. Once created, you
will notice a 'Rate' field in the pump form with a default value of 200.

Optimal Rain uses a default rate of 200ml per 30-second interval. To calibrate to your 
own irrigation system, place one plant container's worth of feed lines in a bucket and
press the 'calibrate' button in the app.

This will turn the pump on for 30 seconds. Measure the amount of water in the bucket in 
milliliters and update the pump's 'Rate' field in the application to this value.
