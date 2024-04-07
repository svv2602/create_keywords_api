class AddSentenceUaToSeoContentTextSentence < ActiveRecord::Migration[7.1]
  def change
    add_column :seo_content_text_sentences, :sentence_ua, :string, default: ""
  end
end
