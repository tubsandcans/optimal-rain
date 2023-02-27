### Watering schedule throughout a crop's lifecycle with Raspberry Pi

This is currently in extreme-prototype phase, aiming at achieveing the most basic functionality. I only intend to use this with one pump simultaneously but the code is structured such that other pins could be used without having to make any drastic modifications. This is why my in-use pin of #17 is hardcoded in the ACTIVE_PINS map.

#### Minimal interface

- Simply select a date and time from the form field and submit to create or modify a cycle.
- Cycle Start's time should be the intended light-on time during the bloom phase.
- For now, watering volumes are calculated using a percentage of 1 gallon container size.
  - TODO: add an additional 'container_size' form input to make this configure-able.

#### Install, create databases and perform migrations

Make sure sqlite3 is installed

`bundle install`

`bundle exec rake db:migrate`

`APP_ENV=test bundle exec rake db:migrate`

#### Add crontab entry to always run at startup:

`@reboot sh /home/pi/optimal_rain/startup.sh`
