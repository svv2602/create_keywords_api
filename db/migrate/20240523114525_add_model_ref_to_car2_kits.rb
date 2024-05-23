class AddModelRefToCar2Kits < ActiveRecord::Migration[7.1]
  def change
    add_reference :test_table_car2_kits,
                  :test_table_car2_models,
                  foreign_key: true
  end

end
