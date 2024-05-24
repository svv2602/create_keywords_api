class AddModelRefToCar2KitsTyreSizes < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :test_table_car2_kit_tyre_sizes,
                    :test_table_car2_kits,
                    column: :kit
  end




end
