class AddLanguageToCityCopies < ActiveRecord::Migration[7.1]
  def change
    add_column :city_copies, :language, :string
  end
end
