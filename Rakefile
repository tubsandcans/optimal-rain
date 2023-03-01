require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

namespace :db do
  database_url = if ENV.fetch("APP_ENV", "development") == "test"
    "sqlite://optimal_rain_test.db"
  else
    "sqlite://optimal_rain.db"
  end
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    require "sequel/core"
    Sequel.extension :migration
    version = args[:version]&.to_i
    Sequel.connect(database_url) do |db|
      Sequel::Migrator.run(db, "db/migrations", target: version)
    end
  end
end

unless Gem::Specification.find_all_by_name("rubocop").empty?
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
end

unless Gem::Specification.find_all_by_name("bundler-audit").empty?
  require "bundler/audit/task"
  Bundler::Audit::Task.new
end

task default: %i[
  rubocop
  spec
  bundle:audit
]
