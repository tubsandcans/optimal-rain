require "rspec"

describe "Pump" do
  let(:start_time) { Time.now }
  let(:first_watering) { start_time + (5 * 24 * 60 * 60) }

  before do
    OptimalRain::Pump.insert(pin_number: 17, cycle_start: start_time)
  end

  context "when cycle-start is Time.now" do
    let(:pump) { OptimalRain::Pump.last }
    it "schedules the first watering event 5 days out" do
      pump.next_watering
      watering = OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]
      watering_start = first_watering
      expect(watering.begin_watering_event).to be_within(1).of(watering_start)
      expect(watering.end_watering_event).to be_within(1).of(watering_start +
                                                   watering.duration_in_seconds)
      watering.cancel
      OptimalRain::ACTIVE_SCHEDULES[pump.pin_number] = nil
    end

    it "schedules the next watering after the last scheduled job completes" do
      pump.next_watering
      watering = OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]
      watering_start = first_watering
      allow(Time).to receive(:now).and_return(first_watering + 1)
      # trigger execution of jobs just like Rufus-scheduler would when triggered
      watering.scheduler.jobs.first.callable.call
      expect(OptimalRain::ACTIVE_PINS[pump.pin_number].value).to eq 1
      watering.scheduler.jobs.last.callable.call
      expect(OptimalRain::ACTIVE_PINS[pump.pin_number].value).to eq 0
      # the next watering will be 20 minutes from the last watering:
      watering = OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]
      expect(watering.begin_watering_event).to be_within(1)
        .of(watering_start + (20 * 60))
      OptimalRain::ACTIVE_SCHEDULES[pump.pin_number] = nil
    end

    it "will run next_watering() tomorrow at light-on time after today's last watering" do
      # right after last watering of the day (60 minutes + 1 second from start_time)
      right_after_last_watering = first_watering + (60 * 60) + 1
      allow(Time).to receive(:now).and_return(right_after_last_watering)
      pump.next_watering
      # stub Time.now to be the start-time of the job
      allow(Time).to receive(:now).and_return(
        OptimalRain::ACTIVE_SCHEDULES[pump.pin_number].jobs.first.original
      )
      # call the job (pump.next_watering) to create a Watering object for this pin
      OptimalRain::ACTIVE_SCHEDULES[pump.pin_number].jobs.first.call
      watering = OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]
      # verify that a watering event is scheduled at first_watering + 1 day
      expect(watering.begin_watering_event).to be_within(1)
        .of(first_watering + (24 * 60 * 60))
    end
  end

  context "when cycle start was 65 days ago (cycle is completed)" do
    let(:pump) { OptimalRain::Pump.last }
    it "is all out of watering events" do
      pump.cycle_start = start_time - (65 * 24 * 60 * 60)
      pump.next_watering
      expect(OptimalRain::ACTIVE_SCHEDULES[pump.pin_number]).to be_nil
    end
  end
end
