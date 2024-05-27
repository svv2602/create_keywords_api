class AddTranslitToTestTableCar2Brands < ActiveRecord::Migration[7.1]
  def change
    add_column :test_table_car2_brands, :translit, :string
  end
end
