require "rspec"

describe "Pump" do
  let(:start_time) { Time.now }

  before do
    Pump.insert(pin_number: 17, cycle_start: start_time)
  end

  after do
    # Do nothing
  end

  #
  # allow(Time).to receive(:now).and_return(@time_now)

  context "when cycle-start is Time.now" do
    let(:pump) { Pump.last }
    it "schedules the first watering event 5 days out" do
      pump.next_watering
      expect(pump.pin_number).to eql 17
      schedule = TurnAndBurnRunner::ACTIVE_SCHEDULES[pump.pin_number].jobs.first.original
      expect(schedule).to eql(start_time + (5 * 24 * 60 * 60))
    end
  end
end
