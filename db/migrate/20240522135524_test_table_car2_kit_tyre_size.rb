class TestTableCar2KitTyreSize < ActiveRecord::Migration[7.1]
  def change
    create_table :test_table_car2_kit_tyre_sizes, id: false do |t|
      t.integer :id, primary_key: true
      t.integer :kit
      t.string :width
      t.string :height
      t.string :diameter
      t.string :type_disabled
      t.string :axle
      t.string :axle_group

      t.timestamps
    end
  end
end
