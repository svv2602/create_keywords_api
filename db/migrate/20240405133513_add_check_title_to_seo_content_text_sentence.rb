class AddCheckTitleToSeoContentTextSentence < ActiveRecord::Migration[7.1]
  def change
    add_column :seo_content_text_sentences, :check_title, :integer, default: 0
  end
end
