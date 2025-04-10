class AddLanguageToSeasonCopies < ActiveRecord::Migration[7.1]
  def change
    add_column :season_copies, :language, :string
  end
end
