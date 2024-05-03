class AddTypeUrlToBrands < ActiveRecord::Migration[7.1]
  def change
    add_column :brands, :type_url, :integer, default: 0
  end
end
