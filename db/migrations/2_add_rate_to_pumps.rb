Sequel.migration do
  change do
    add_column :pumps, :rate, Integer, null: false
  end
end
