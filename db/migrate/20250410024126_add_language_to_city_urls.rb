class AddLanguageToCityUrls < ActiveRecord::Migration[7.1]
  def change
    add_column :city_urls, :language, :string
  end
end
