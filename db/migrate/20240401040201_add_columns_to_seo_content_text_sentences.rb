class AddColumnsToSeoContentTextSentences < ActiveRecord::Migration[7.1]
  def change
    add_column :seo_content_text_sentences, :id_text, :integer
    add_column :seo_content_text_sentences, :type_text, :string
  end
end
