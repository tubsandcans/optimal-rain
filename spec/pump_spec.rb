require "rspec"

describe "Pump" do
  let(:start_time) { override_start || Time.now }
  let(:first_watering) { start_time + (5 * OptimalRain::DAY) }

  before do
    OptimalRain::PUMP_PINS.each do |pin, _gpio|
      pump = OptimalRain::Pump.new(pin_number: pin, cycle_start: start_time)
      pump.rate
      pump.save_changes
    end
  end

  context "when from-value is default value of current-time" do
    let(:override_start) { nil }
    let(:pump) { OptimalRain::Pump.last }
    let(:watering) {
      {schedule: OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]}
    }

    before do
      pump.schedule_next_watering
    end

    after do
      watering[:schedule].cancel
      OptimalRain::ACTIVE_SCHEDULES[pump.pin_number] = nil
    end

    it "schedules the first begin-watering event 5 days from now" do
      expect(watering[:schedule].schedule_watering_event)
        .to be_within(1).of(first_watering)
    end

    it "schedules the first end-watering event 5 days + watering-duration from now" do
      expect(watering[:schedule].scheduler.jobs.last.original).to be_within(1)
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
      pump.schedule_next_watering(from: (first_watering + 1))
    end

    after do
      OptimalRain::ACTIVE_SCHEDULES[pump.pin_number] = nil
    end

    it "schedules the next watering after the last scheduled job completes" do
      watering = OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]
      # the next watering will be 20 minutes from the last watering:
      expect(watering.watering_event_start).to be_within(1)
        .of(first_watering + (20 * 60))
      watering.cancel
    end
  end

  context "when from-value is one hour after the cycle's first watering" do
    let(:override_start) { nil }
    let(:pump) { OptimalRain::Pump.last }

    before do
      pump.schedule_next_watering(from: first_watering + OptimalRain::HOUR + 1)
    end

    after do
      OptimalRain::ACTIVE_SCHEDULES[pump.pin_number] = nil
    end

    it "schedules the next watering event for tomorrow at light-on time" do
      # call the job (pump.next_watering) to create a Watering object for this pin
      OptimalRain::ACTIVE_SCHEDULES[pump.pin_number].scheduler.jobs.first.call
      # verify that a watering event is scheduled at first_watering + 1 day
      expect(OptimalRain::ACTIVE_SCHEDULES[pump.pin_number].watering_event_start)
        .to be_within(1).of(first_watering + OptimalRain::DAY)
    end
  end

  context "when cycle start was 65 days ago (cycle is completed)" do
    let(:override_start) { nil }
    let(:pump) { OptimalRain::Pump.last }

    it "is all out of watering events" do
      pump.cycle_start = start_time - (65 * OptimalRain::DAY)
      pump.schedule_next_watering
      expect(OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]).to be_nil
    end
  end

  context "when cycle-start is in the future" do
    let(:override_start) { Time.now + 2 * OptimalRain::DAY }
    let(:pump) { OptimalRain::Pump.last }

    it "schedules the first watering event 5 days from cycle-start" do
      pump.schedule_next_watering
      first_watering_start = OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]
        .scheduler.jobs.first.original
      expect(first_watering_start).to be_within(1).of(first_watering)
    end
  end

  context "when in early bloom phase (days 11-20) at light-on time" do
    let(:override_start) { Time.now - 11 * OptimalRain::DAY }
    let(:pump) { OptimalRain::Pump.last }

    it "schedules the next watering event 2 hours from light-on time" do
      pump.schedule_next_watering
      next_watering_start = OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]
        .scheduler.jobs.first.original
      expect(next_watering_start).to be_within(2 * OptimalRain::HOUR).of(Time.now)
    end
  end

  context "when in bulking phase (days 21-30) at light-on time" do
    let(:override_start) { Time.now - 21 * OptimalRain::DAY }
    let(:pump) { OptimalRain::Pump.last }

    it "schedules the next watering event 1 hour from light-on time" do
      pump.schedule_next_watering
      next_watering_start = OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]
        .scheduler.jobs.first.original
      expect(next_watering_start).to be_within(OptimalRain::HOUR).of(Time.now)
    end
  end

  context "when in bulking phase right after last generative watering time" do
    let(:override_start) { Time.now - ((30 * OptimalRain::DAY) + (140 * 60)) }
    let(:pump) { OptimalRain::Pump.last }

    it "schedules a vegetative watering in 20 minutes" do
      pump.schedule_next_watering
      next_watering_start = OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]
        .scheduler.jobs.first.original
      expect(next_watering_start).to be_within(440 * 60).of(Time.now)
    end
  end
end
