class AddBrandRefToCar2Models < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :test_table_car2_models,
                    :test_table_car2_brands,
                    column: :brand
  end
end
