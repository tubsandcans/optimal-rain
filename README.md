### Watering schedule throughout a crop's lifecycle with Raspberry Pi
This is currently in extreme-prototype phase, aiming at achieveing the most basic functionality. I only intend to use this with one pump simultaneously but the code is structured such that other pins could be used without having to make any drastic modifications. This is why my in-use pin of #17 is hardcoded in the ACTIVE_PINS map.

#### Minimal interface
* Simply enter a date-time string like '2023-02-22 07:00:00' into the Cycle Start field.
* Cycles can be modified or deleted
* Cycle Start's time should be the intended light-on time during the bloom phase.
* For now, watering volumes are calculated using a percentage of 1 gallon.
  * This should at some point allow for other container sizes. 

#### Setup
Make sure sqlite3 is installed, then `bundle install`
##### Create database file and migrate:
`sqlite3 turn_and_burn.db`
~~~
require 'sequel'

DB = Sequel.connect("sqlite://turn_and_burn.db")
DB.create_table :pumps do
  primary_key :id
  Integer :pin_number, unique: true, null: false
  DateTime :cycle_start, null: false
end
~~~
#### Add crontab entry to always run at startup:
`@reboot sh /home/pi/turn_and_burn_runner/startup.sh`
