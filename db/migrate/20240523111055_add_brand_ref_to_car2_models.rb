class AddBrandRefToCar2Models < ActiveRecord::Migration[7.1]
  def change
    add_reference :test_table_car2_models, :test_table_car2_brand, foreign_key: true
  end
end
