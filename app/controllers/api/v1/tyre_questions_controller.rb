# app/controllers/api/openai_controller.rb

class Api::V1::TyreQuestionsController < ApplicationController
  include ServiceTable
  include Constants

  def questions
    list_questions = []

    # формирование основного блока вопрос ответ
    rand(1..2).times do
      list_questions << question unless question[:question] == ""
    end

    list_questions += questions_dop

    render json: { list_questions: list_questions }
  end

  def question

    # Используется для таблицы вопросов по легковым шинам
    table = 'TyresFaq'
    table_copy = table + 'Copy' # Преобразуем имя таблицы-копии
    copy_table_to_table_copy_if_empty(table, table_copy)
    question = find_and_destroy_random_record(table_copy).question
    # puts "question = #{question}"

    # Делается рерайт полученного случайного вопроса
    topics = "Сделай краткий рерайт вопроса: #{question}."

    question = ContentWriter.new.write_draft_post(topics, 150)['choices'][0]['message']['content'].strip

    # Получение ответа на вопрос
    topics = "Дай краткий ответ, не более 300 печатных символов, на вопрос: #{question}."
    answer = ContentWriter.new.write_draft_post(topics, 500)
    answer = answer['choices'][0]['message']['content'].strip

    rezult = { question: question, answer: answer }

  end

  def sinonim(str)
    rand(0..20) % 2 ? str += " Вместо слова 'шины' необходимо использовать синонимы" : str
  end

  def question_brand(el)
    question_random = el[:questions].sample
    puts question_random
    answer = ""
    topics = sinonim("Сделай краткий рерайт вопроса: #{question_random[:question]}.")
    question = ContentWriter.new.write_draft_post(topics, 150)['choices'][0]['message']['content'].strip
    # question = format_str(question)
    random_brands = el[:aliases].sample(rand(6..10))
    random_brands.each_with_index do |el, i|
      answer += "<a href='#{question_random[:url]}#{el[:alias]}/'>#{i + 1}. #{el[:name]}</a>    "
    end
    rezult = { question: question, answer: "[#{answer}]" }
  end

  def questions_dop
    list_questions = []
    arr = [BRANDS, CITIES, DIAMETERS].sample(rand(1..2))
    arr.each do |constant|
      list_questions << question_brand(constant)
    end

    list_questions

  end

end