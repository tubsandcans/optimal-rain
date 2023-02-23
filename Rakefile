namespace :db do
  database_url = if ENV.fetch("APP_ENV", "development") == "test"
    "sqlite://turn_and_burn_test.db"
  else
    "sqlite://turn_and_burn.db"
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
