class AddTypeUrlToBrandCopies < ActiveRecord::Migration[7.1]
  def change
    add_column :brand_copies, :type_url, :integer, default: 0
  end
end
