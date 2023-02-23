require "rspec"
require "capybara"
require "capybara/dsl"
require_relative "../config"

describe "App" do
  include Capybara::DSL

  let(:app) { TurnAndBurnRunner.app }

  before do
    Capybara.app = app
  end

  it "renders a new cycle form" do
    visit "/"
    expect(page).to have_selector("form#new_cycle_form")
  end
end
