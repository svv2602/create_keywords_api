class AddTypeTagToSeoContentText < ActiveRecord::Migration[7.1]
  def change
    add_column :seo_content_texts, :type_tag, :integer
  end
end
