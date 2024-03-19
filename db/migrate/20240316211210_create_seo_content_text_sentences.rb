class CreateSeoContentTextSentences < ActiveRecord::Migration[7.1]
  def change
    create_table :seo_content_text_sentences do |t|
      t.string :str_seo_text
      t.integer :str_number
      t.string :sentence
      t.integer :num_snt_in_str

      t.timestamps
    end
  end
end
