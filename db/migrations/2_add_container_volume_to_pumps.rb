require_relative "../../models/watering"

Sequel.migration do
  up do
    add_column :pumps, :container_volume, :float
    from(:pumps).update(container_volume: OptimalRain::ML_PER_GAL)
  end

  down do
    drop_column :pumps, :container_volume
  end
end
