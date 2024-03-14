class AddFieldsToSeoContentTexts < ActiveRecord::Migration[7.1]
  def change
    add_column :seo_content_texts, :type_text, :text
    add_column :seo_content_texts, :order_out, :integer, default: 0
  end
end
