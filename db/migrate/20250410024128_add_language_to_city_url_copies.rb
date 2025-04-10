class AddLanguageToCityUrlCopies < ActiveRecord::Migration[7.1]
  def change
    add_column :city_url_copies, :language, :string
  end
end
