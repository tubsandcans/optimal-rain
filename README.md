### Watering schedule throughout a crop's lifecycle with Raspberry Pi
This is currently in extreme-prototype phase, aiming at achieveing the most basic functionality. I only intend to use this with one pump simultaneously but the code is structured such that other pins could be used without having to make any drastic modifications. This is why my in-use pin of #17 is hardcoded in the ACTIVE_PINS map.

#### Minimal interface
* Simply enter a date-time string like '2023-02-22 07:00:00' into the Cycle Start field.
* Cycles can be modified or deleted
* Cycle Start's time should be the intended light-on time during the bloom phase.
* For now, watering volumes are calculated using a percentage of 1 gallon.
  * This should at some point allow for other container sizes. 

#### Setup
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
