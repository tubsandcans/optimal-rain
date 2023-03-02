[![Ruby](https://github.com/tubsandcans/optimal-rain/actions/workflows/ruby.yml/badge.svg?branch=main)](https://github.com/tubsandcans/optimal-rain/actions/workflows/ruby.yml)

## Manage watering schedule throughout a crop's lifecycle with Raspberry Pi (and Sinatra)

### GPIO

Active pins can be set by environment variable `GPIO_PINS`.

- If `GPIO_PINS` is not present, pin 17 will be used as the one active pin.
- Multiple pump pins: `GPIO_PINS="17 18 19"`.
- Don't forget to add to the startup.sh script before deploying to a Raspberry pi.

### Minimal interface

- Select a date and time from the form field and submit to create or modify a cycle.
- Cycle Start's time should be the intended light-on time during the bloom phase.
- For now, watering volumes are calculated using a percentage of 1 gallon container size.
  - Eventually: add an additional 'container_size' form input to make this configure-able.

### Install, create databases and perform migrations

Make sure sqlite3 is installed

`bundle install`

`bundle exec rake db:migrate`

`APP_ENV=test bundle exec rake db:migrate`

### Add crontab entry on Raspberry pi to always run at startup:

`@reboot sh /home/pi/optimal-rain/startup.sh`
