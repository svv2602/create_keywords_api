class AddLanguageToCities < ActiveRecord::Migration[7.1]
  def change
    add_column :cities, :language, :string
  end
end
