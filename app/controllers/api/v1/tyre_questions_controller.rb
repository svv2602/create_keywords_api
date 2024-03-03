# app/controllers/api/openai_controller.rb

class Api::V1::TyreQuestionsController < ApplicationController
  include ServiceTable
  include Constants

  def questions
    list_questions = []

    # формирование основного блока вопрос ответ
    rand(2..4).times do
      list_questions << question unless question[:question] == ""
    end

    # добавляем еще 1-4 вопроса по константам
    list_questions += questions_dop

    # форматируем ответ
    str = ""
    list_questions.each do |el|
      str += format_hash_question_html(el)
    end

    result = format_hash_question_with_head_html(str)
    puts result
    render json: { list_questions: result }
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
    # Убирем лишний текст после знака вопроса
    question = question.split("?").first

    # Получение ответа на вопрос
    topics = "Дай краткий ответ, не более 300 печатных символов, на вопрос: #{question}."
    answer = ContentWriter.new.write_draft_post(topics, 500)
    answer = answer['choices'][0]['message']['content'].strip

    rezult = { question: question, answer: answer }

  end

  def sinonim(str)
    rand(0..20) % 2 ? str = "Используя вместо слова 'шины' синонимы, #{str.downcase} " : str
    # true ? str = "Используя вместо слова 'шины' синонимы, #{str.downcase} "  : str
  end

  def question_const(el)
    question_random = el[:questions].sample
    answer = ""
    topics = sinonim("Cделай краткий рерайт вопроса: #{question_random[:question]}.")
    question = ContentWriter.new.write_draft_post(topics, 150)['choices'][0]['message']['content'].strip

    el[:aliases].size < 10 ? max = el[:aliases].size : max = 10
    random_brands = el[:aliases].sample(rand(6..max)) # случайное количество ответов
    # сборка в ответ элементов массива
    random_brands.each_with_index do |el, i|
      answer += "<a href='#{question_random[:url]}#{el[:alias]}/'>#{i + 1}. #{el[:name]}</a>    "
    end
    rezult = { question: question, answer: "[#{answer}]" }
  end

  def questions_dop
    # формирование количяества доп вопросов
    list_questions = []
    list = [BRANDS, CITIES, DIAMETERS, TOP_SIZE]
    arr = list.sample(rand(1..3))
    arr.each do |constant|
      list_questions << question_const(constant)
    end

    # добавление вопросов по грузовым шинам или дискам
    if rand(1..6) % 5 == 0
      list = [DIAMETERS_TRUCK, SIZE_TRUCK, WHEELS]
      list_questions << question_const(list.sample)
    end

    list_questions

  end

  def format_hash_question_html(hash_question)
    rezult = "<div itemscope='' itemprop='mainEntity' itemtype='https://schema.org/Question'>  "
    rezult += "<h3 itemprop='name'> "
    rezult += hash_question[:question]
    rezult += "</h3> "
    rezult += "<div itemprop='acceptedAnswer' itemscope='' itemtype='https://schema.org/Answer'> "
    rezult += "<p itemprop='text'> "
    rezult += hash_question[:answer]
    rezult += "</p> "
    rezult += "</div> "
    rezult += "</div> "
    return rezult
  end

  def format_hash_question_with_head_html(str)
    rezult = "<div itemscope='' itemtype='https://schema.org/FAQPage'>  "
    rezult += "<h2>Часто задаваемые вопросы (FAQ):</h2> "
    rezult += str
    rezult += "</div><br> "
    return rezult
  end

end