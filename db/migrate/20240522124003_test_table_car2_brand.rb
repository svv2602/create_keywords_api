class TestTableCar2Brand < ActiveRecord::Migration[7.1]
  def change
    create_table :test_table_car2_brands, id: false do |t|
      t.integer :id, primary_key: true
      t.string :name

      t.timestamps
    end
  end

end
