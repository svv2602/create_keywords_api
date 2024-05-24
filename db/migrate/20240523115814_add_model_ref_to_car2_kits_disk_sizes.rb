class AddModelRefToCar2KitsDiskSizes < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :test_table_car2_kit_disk_sizes,
                    :test_table_car2_kits,
                    column: :kit
  end


end
