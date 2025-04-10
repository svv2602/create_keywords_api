class AddLanguageToSeasons < ActiveRecord::Migration[7.1]
  def change
    add_column :seasons, :language, :string
  end
end
