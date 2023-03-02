require "rspec"

describe "Pump" do
  let(:start_time) { override_start || Time.now }
  let(:first_watering) { start_time + (5 * 24 * 60 * 60) }

  before do
    OptimalRain::PUMP_PINS.each do |pin, _gpio|
      OptimalRain::Pump.insert(pin_number: pin, cycle_start: start_time)
    end
  end

  context "when from-value is not set" do
    let(:override_start) { nil }
    let(:pump) { OptimalRain::Pump.last }
    let(:watering) {
      {schedule: OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]}
    }

    before do
      pump.next_watering
    end

    after do
      watering[:schedule].cancel
      OptimalRain::ACTIVE_SCHEDULES[pump.pin_number] = nil
    end

    it "schedules the first begin-watering event 5 days from now" do
      expect(watering[:schedule].begin_watering_event).to be_within(1).of(first_watering)
    end

    it "schedules the first end-watering event 5 days + watering-duration from now" do
      expect(watering[:schedule].end_watering_event).to be_within(1)
        .of(first_watering + watering[:schedule].duration_in_seconds)
    end

    it "sets pump pin-value to 1/on when the first scheduled job is called" do
      watering[:schedule] = OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]
      # trigger execution of jobs just like Rufus-scheduler would when triggered
      watering[:schedule].scheduler.jobs.first.callable.call
      expect(OptimalRain::ACTIVE_PINS[pump.pin_number].value.to_i).to eq 1
    end

    it "sets pump pin-value to 0/off when the last scheduled job is called" do
      watering[:schedule] = OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]
      watering[:schedule].scheduler.jobs.last.callable.call
      expect(OptimalRain::ACTIVE_PINS[pump.pin_number].value.to_i).to eq 0
    end
  end

  context "when from-value is set to 1 second after the first begin-watering event" do
    let(:override_start) { nil }
    let(:pump) { OptimalRain::Pump.last }

    before do
      pump.next_watering(from: first_watering + 1)
    end

    after do
      OptimalRain::ACTIVE_SCHEDULES[pump.pin_number] = nil
    end

    it "schedules the next watering after the last scheduled job completes" do
      watering = OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]
      # the next watering will be 20 minutes from the last watering:
      expect(watering.begin_watering_event).to be_within(1)
        .of(first_watering + (20 * 60))
      watering.cancel
    end
  end

  context "when from-value is set to 1 second after the last watering event for the 'day'" do
    let(:override_start) { nil }
    let(:pump) { OptimalRain::Pump.last }

    before do
      pump.next_watering(from: first_watering + (60 * 60) + 1)
    end

    after do
      OptimalRain::ACTIVE_SCHEDULES[pump.pin_number] = nil
    end

    it "schedules the next begin-watering event for tomorrow at light-on time" do
      # call the job (pump.next_watering) to create a Watering object for this pin
      OptimalRain::ACTIVE_SCHEDULES[pump.pin_number].scheduler.jobs.first.call
      # verify that a watering event is scheduled at first_watering + 1 day
      expect(OptimalRain::ACTIVE_SCHEDULES[pump.pin_number].begin_watering_event)
        .to be_within(1).of(first_watering + (24 * 60 * 60))
    end
  end

  context "when cycle start was 65 days ago (cycle is completed)" do
    let(:override_start) { nil }
    let(:pump) { OptimalRain::Pump.last }

    it "is all out of watering events" do
      pump.cycle_start = start_time - (65 * 24 * 60 * 60)
      pump.next_watering
      expect(OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]).to be_nil
    end
  end

  context "when cycle-start is in the future" do
    let(:override_start) { Time.now + 2 * 24 * 60 * 60 }
    let(:pump) { OptimalRain::Pump.last }

    it "schedules the first watering event 5 days from cycle-start" do
      pump.next_watering
      first_watering_start = OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]
        .scheduler.jobs.first.original
      expect(first_watering_start).to be_within(1).of(first_watering)
    end
  end
end
