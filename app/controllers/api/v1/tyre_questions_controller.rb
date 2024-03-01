# app/controllers/api/openai_controller.rb

class Api::V1::TyreQuestionsController < ApplicationController
  include ServiceTable

  def generate_questions
    # Определите массив тем.

    topics = ""

    result = ContentWriter.new.write_draft_post(questions, 500)

    # puts "prompt =========  #{prompt}"
    render json: { result: result }
    puts result
  end

  def questions
    table = 'TyresFaq'

    table_copy = table + 'Copy' # Преобразуем имя таблицы-копии
    copy_table_to_table_copy_if_empty(table, table_copy)
    question = find_and_destroy_random_record(table_copy).question
    topics = "Дай краткий ответ на вопрос: #{question}. Ответ оберни тегами <p>"
    result = ContentWriter.new.write_draft_post(topics, 100)

    render json: { question: question, result: result['choices'][0]['message']['content'].strip }
    puts result
  end

end