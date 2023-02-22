# frozen_string_literal: true

require "rspec"
require_relative "../config"

describe "App" do
  include Rack::Test::Methods
  let(:app) { TurnAndBurnRunner.app }

  before do
    # Do nothing
  end

  after do
    # Do nothing
  end

  it "says hello" do
    get "/"
    expect(last_response).to be_ok
    expect(last_response.body).to eq(
      "<html>\n" + "<h1>Turn and Burn runner</h1>\n" \
      "<h4>New turn and burn cycle for pin 17:</h4>\n" \
      "<form action='/' id='new_cycle_form' method='POST'>\n" \
      "<span>Cycle Start</span>\n" \
      "<input name='pin_number' type='hidden' value='17'>\n" \
      "<input name='cycle_start' type='text'>\n" \
      "<button type='submit'>Set Cycle</button>\n" \
      "</form>\n" + "\n" + "</html>\n"
    )
  end
end
