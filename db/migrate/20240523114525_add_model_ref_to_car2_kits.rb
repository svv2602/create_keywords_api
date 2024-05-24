class AddModelRefToCar2Kits < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :test_table_car2_kits,
                    :test_table_car2_models,
                    column: :model
  end



end
