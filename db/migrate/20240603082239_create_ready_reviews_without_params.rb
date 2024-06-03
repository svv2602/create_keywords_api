class CreateReadyReviewsWithoutParams < ActiveRecord::Migration[7.1]
  def change
    create_table :ready_reviews_without_params do |t|
      t.text :review_ru
      t.text :review_ua
      t.string :control
      t.string :gender
      t.integer :characters
      t.timestamps
    end
  end
end
