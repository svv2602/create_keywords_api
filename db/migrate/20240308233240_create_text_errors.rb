class CreateTextErrors < ActiveRecord::Migration[7.1]
  def change
    create_table :text_errors do |t|
      t.string :line
      t.string :type_line

      t.timestamps
    end
  end
end
