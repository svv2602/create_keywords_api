class CreateTyresFaqCopies < ActiveRecord::Migration[7.1]
  def change
    create_table :tyres_faq_copies do |t|
      t.string :question
      t.string :theme

      t.timestamps
    end
  end
end
