class AddLanguageToBrandCopies < ActiveRecord::Migration[7.1]
  def change
    add_column :brand_copies, :language, :string
  end
end
