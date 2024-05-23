class AddModelRefToCar2KitsTyreSizes < ActiveRecord::Migration[7.1]
  def change
    add_reference :test_table_car2_kit_tyre_sizes,
                  :test_table_car2_kits,
                  foreign_key: true
  end
end
