class CreateSeasons < ActiveRecord::Migration[7.1]
  def change
    create_table :seasons do |t|
      t.string :name
      t.string :url

      t.timestamps
    end
  end
end
