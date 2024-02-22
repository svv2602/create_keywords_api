class CreateSeasonCopies < ActiveRecord::Migration[7.1]
  def change
    create_table :season_copies do |t|
      t.string :name
      t.string :url

      t.timestamps
    end
  end
end
