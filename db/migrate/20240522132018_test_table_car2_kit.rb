class TestTableCar2Kit < ActiveRecord::Migration[7.1]
  def change
    create_table :test_table_car2_kits, id: false do |t|
      t.integer :id, primary_key: true
      t.integer :model
      t.string :year
      t.string :name
      t.string :pcd
      t.string :bolt_count
      t.string :dia
      t.string :bolt_size

      t.timestamps
    end
  end
end
