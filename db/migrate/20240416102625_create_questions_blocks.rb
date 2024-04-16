class CreateQuestionsBlocks < ActiveRecord::Migration[7.1]
  def change
    create_table :questions_blocks do |t|
      t.integer :type_paragraph, default: 0
      t.integer :type_season, default: 0
      t.string :question_ru, default: ""
      t.string :answer_ru, default: ""
      t.string :question_ua, default: ""
      t.string :answer_ua, default: ""

      t.timestamps
    end
  end
end
