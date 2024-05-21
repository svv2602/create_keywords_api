class CreateReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :reviews do |t|
      t.string :gender
      t.string :season
      t.string :type_review
      t.text   :review_ru
      t.text   :review_ua
      t.integer :param1
      t.integer :param2
      t.integer :param3
      t.integer :param4
      t.integer :param5
      t.integer :param6
      t.timestamps
    end
  end
end
