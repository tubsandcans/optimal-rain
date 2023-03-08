Sequel.migration do
  change do
    create_table :pumps do
      primary_key :id
      Integer :pin_number, unique: true, null: false
      Integer :rate, null: false
      DateTime :cycle_start, null: false
    end
  end
end
