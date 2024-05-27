class AddTranslitToTestTableCar2Models < ActiveRecord::Migration[7.1]
  def change
    add_column :test_table_car2_models, :translit, :string
  end
end
