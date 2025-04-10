class AddLanguageToAddons < ActiveRecord::Migration[7.1]
  def change
    add_column :addons, :language, :string
  end
end
