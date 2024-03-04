class CreateTrackTyresFaqCopies < ActiveRecord::Migration[7.1]
  def change
    create_table :track_tyres_faq_copies do |t|
      t.string :question
      t.string :theme

      t.timestamps
    end
  end
end
