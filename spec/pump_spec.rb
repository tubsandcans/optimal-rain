require "rspec"

describe "Pump" do
  let(:start_time) { override_start || Time.now }
  let(:first_watering) { start_time + (5 * 24 * 60 * 60) }

  before do
    OptimalRain::Pump.insert(pin_number: OptimalRain::PUMP_PIN, cycle_start: start_time)
  end

  context "when cycle-start is Time.now" do
    let(:override_start) { nil }
    let(:pump) { OptimalRain::Pump.last }
    let(:watering) { OptimalRain::ACTIVE_SCHEDULES[pump.pin_number] }

    before do
      pump.next_watering
    end

    after do
      OptimalRain::ACTIVE_SCHEDULES[pump.pin_number] = nil
    end

    it "schedules the first watering event to start 5 days from cycle-start" do
      expect(watering.begin_watering_event).to be_within(1).of(first_watering)
      watering.cancel
    end

    it "schedules a stop watering event for every start watering event" do
      expect(watering.end_watering_event).to be_within(1)
        .of(first_watering + watering.duration_in_seconds)
      watering.cancel
    end
  end

  context "when current time is 1 second after a water event has begun" do
    let(:override_start) { nil }
    let(:pump) { OptimalRain::Pump.last }

    before do
      pump.next_watering(from: first_watering + 1)
    end

    after do
      OptimalRain::ACTIVE_SCHEDULES[pump.pin_number] = nil
    end

    it "will set pump-pin's value to '1'/on when the first scheduled job is called" do
      watering = OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]
      # trigger execution of jobs just like Rufus-scheduler would when triggered
      watering.scheduler.jobs.first.callable.call
      expect(OptimalRain::ACTIVE_PINS[pump.pin_number].get_value.to_i).to eq 1
      watering.cancel
    end

    it "will set pump-pin's value to '0'/off when the last scheduled job is called" do
      watering = OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]
      watering.scheduler.jobs.last.callable.call
      expect(OptimalRain::ACTIVE_PINS[pump.pin_number].get_value.to_i).to eq 0
      watering.cancel
    end

    it "schedules the next watering after the last scheduled job completes", skip_before: true do
      watering = OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]
      # the next watering will be 20 minutes from the last watering:
      expect(watering.begin_watering_event).to be_within(1)
        .of(first_watering + (20 * 60))
      watering.cancel
    end

    def setup_next_day
      # right after last watering of the day (60 minutes + 1 second from start_time)
      right_after_last_watering = first_watering + (60 * 60) + 1
      allow(Time).to receive(:now).and_return(right_after_last_watering)
      pump.next_watering
      # stub Time.now to be the start-time of the job
      allow(Time).to receive(:now).and_return(
        OptimalRain::ACTIVE_SCHEDULES[pump.pin_number].scheduler.jobs.first.original
      )
      # call the job (pump.next_watering) to create a Watering object for this pin
      OptimalRain::ACTIVE_SCHEDULES[pump.pin_number].scheduler.jobs.first.call
    end

    it "will run next_watering() tomorrow at light-on time after today's last watering" do
      setup_next_day
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
