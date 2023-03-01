source "https://rubygems.org"

ruby "~> 3.2.1"

gem "puma"
gem "sequel"
gem "sinatra"
gem "sqlite3"
gem "raspi-gpio", "~> 1.0"
gem "phlex", "~> 1.4"
gem "rackup"
gem "rake", "~> 13.0"
gem "rufus-scheduler"

group :development, :test do
  gem "bundler-audit", require: false
  gem "rubocop", "1.44.1"
  gem "rubocop-rake", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-sequel", require: false
  gem "standard"
end

group :test do
  gem "capybara"
  gem "database_cleaner-sequel"
  gem "rack-test"
  gem "rspec"
end
