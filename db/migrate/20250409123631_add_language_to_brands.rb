class AddLanguageToBrands < ActiveRecord::Migration[7.1]
  def change
    add_column :brands, :language, :string
  end
end
