class RenameTranslitToTranslitRuInTestTableCar2Brands < ActiveRecord::Migration[7.1]
  def change
    rename_column :test_table_car2_brands, :translit, :translit_ru
  end
end
