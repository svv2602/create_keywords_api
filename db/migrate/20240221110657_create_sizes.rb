class CreateSizes < ActiveRecord::Migration[7.1]
  def change
    create_table :sizes do |t|
      t.string :ww
      t.string :hh
      t.string :rr
      t.string :url

      t.timestamps
    end
  end
end
