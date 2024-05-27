class RenameTranslitToTranslitRuInTestTableCar2Models < ActiveRecord::Migration[7.1]
  def change
    rename_column :test_table_car2_models, :translit, :translit_ru
  end
end
