class AddLineUaToTextErrors < ActiveRecord::Migration[7.1]
  def change
    add_column :text_errors, :line_ua, :string
    add_index :text_errors, [:line_ua, :line], unique: true
  end
end
