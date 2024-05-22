class CreateReadyReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :ready_reviews do |t|
      t.integer :id_review
      t.text :review_ru
      t.text :review_ua
      t.string :control
      t.integer :characters

      t.timestamps
    end
  end
end
