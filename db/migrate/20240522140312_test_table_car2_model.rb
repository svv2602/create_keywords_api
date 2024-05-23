class TestTableCar2Model < ActiveRecord::Migration[7.1]
  def change
    create_table :test_table_car2_models, id: false do |t|
      t.integer :id, primary_key: true
      t.integer :brand
      t.string :name

      t.timestamps
    end
  end
end
