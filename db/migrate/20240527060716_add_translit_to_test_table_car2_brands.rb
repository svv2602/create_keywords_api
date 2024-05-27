class AddTranslitToTestTableCar2Brands < ActiveRecord::Migration[7.1]
  def change
    add_column :test_table_car2_brands, :translit_ru, :string
    add_column :test_table_car2_brands, :translit_ua, :string
  end
end
