class AddLanguageToAddonCopies < ActiveRecord::Migration[7.1]
  def change
    add_column :addon_copies, :language, :string
  end
end
