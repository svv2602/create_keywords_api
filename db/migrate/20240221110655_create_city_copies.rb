class CreateCityCopies < ActiveRecord::Migration[7.1]
  def change
    create_table :city_copies do |t|
      t.string :name
      t.string :url

      t.timestamps
    end
  end
end
