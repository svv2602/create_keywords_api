class CreateReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :reviews do |t|
      t.string :gender
      t.string :season
      t.string :type_review
      t.integer :param1
      t.integer :param2
      t.integer :param3
      t.integer :param4
      t.integer :param5
      t.integer :param6
      t.text   :main_string
      t.text   :additional_string
      t.timestamps
    end
  end
end
