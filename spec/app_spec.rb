require "rspec"
require "capybara"
require "capybara/dsl"
require_relative "../config"

describe "App" do
  include Capybara::DSL

  let(:app) { OptimalRain.app }

  before do
    Capybara.app = app
  end

  it "renders a new cycle form" do
    visit "/"
    expect(page)
      .to have_selector("form#pin_#{OptimalRain::PUMP[:pins].keys.first}_cycle_form")
  end
end
