class CreateSeoContentTexts < ActiveRecord::Migration[7.1]
  def change
    create_table :seo_content_texts do |t|
      t.string :str
      t.string :content_type
      t.integer :str_number

      t.timestamps
    end
  end
end
