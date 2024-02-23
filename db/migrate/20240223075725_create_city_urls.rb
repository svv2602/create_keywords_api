class CreateCityUrls < ActiveRecord::Migration[7.1]
  def change
    create_table :city_urls do |t|
      t.string :name
      t.string :url

      t.timestamps
    end
  end
end
