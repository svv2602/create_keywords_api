class AddModelRefToCar2KitsDiskSizes < ActiveRecord::Migration[7.1]
  def change
    add_reference :test_table_car2_kit_disk_sizes,
                  :test_table_car2_kits,
                  foreign_key: true
  end
end
