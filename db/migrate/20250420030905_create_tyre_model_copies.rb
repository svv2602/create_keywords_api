class CreateTyreModelCopies < ActiveRecord::Migration[7.1]
  def change
    create_table :tyre_model_copies do |t|
      t.string :name
      t.string :url
      t.string :language
      t.integer :element_count
      t.string :sezon
      t.string :brand

      t.timestamps
    end
  end
end
