# app/controllers/api/openai_controller.rb

class Api::V1::TyreQuestionsController < ApplicationController
  include ServiceTable
  include Constants

  def questions
    list_questions = []
    table = 'TyresFaq'
    # формирование основного блока вопрос ответ
    rand(2..4).times do
      list_questions << question(table) unless question(table)[:question] == ""
    end
    # добавляем еще 1-4 вопроса по константам
    list_questions += questions_dop([CITIES, BRANDS, DIAMETERS, TOP_SIZE],
                                    [DIAMETERS_TRUCK, BRANDS_TRUCK, SIZE_TRUCK, DIAMETERS_WHEELS, BRANDS_WHEELS])

    result = format_question_full(list_questions)
    puts result
    render json: { list_questions: result }
  end

  def questions_track
    list_questions = []
    table = 'TrackTyresFaq'
    # формирование основного блока вопрос ответ
    rand(2..4).times do
      list_questions << question(table) unless question(table)[:question] == ""
    end
    # добавляем еще 1-4 вопроса по константам
    list_questions += questions_dop([CITIES, DIAMETERS_TRUCK, BRANDS_TRUCK, SIZE_TRUCK],
                                    [BRANDS, DIAMETERS, TOP_SIZE, DIAMETERS_WHEELS, BRANDS_WHEELS])

    result = format_question_full(list_questions)
    puts result
    render json: { list_questions: result }
  end

  def questions_diski
    list_questions = []
    table = 'DiskiFaq'
    # формирование основного блока вопрос ответ
    rand(2..4).times do
      list_questions << question(table) unless question(table)[:question] == ""
    end
    # добавляем еще 1-4 вопроса по константам
    list_questions += questions_dop([CITIES, DIAMETERS_WHEELS, BRANDS_WHEELS],
                                    [BRANDS, DIAMETERS, TOP_SIZE, DIAMETERS_TRUCK, BRANDS_TRUCK, SIZE_TRUCK])

    result = format_question_full(list_questions)
    puts result
    render json: { list_questions: result }
  end

  def format_question_full(list_questions)
    # форматируем ответ
    str = ""
    list_questions.each do |el|
      str += format_hash_question_html(el)
    end
    result = format_hash_question_with_head_html(str)
    return result
  end

  def question(table)
    # Используется для таблицы вопросов по легковым шинам
    # table = 'TyresFaq'
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
    rand(0..20) % 2 ? str = "Используя вместо слова 'шины' синонимы, такие как: 'резина','автошины','колеса', 'покрышки', #{str.downcase} " : str
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
    answer = answer.gsub("prokoleso.ua", "prokoleso.ua/ua") if rand(1..10) % 2 == 0
    rezult = { question: question, answer: "[#{answer}]" }
  end

  def questions_dop(list1, list2)
    # формирование количяества доп вопросов
    list_questions = []
    arr = list1.sample(rand(2..3))
    arr.each do |constant|
      list_questions << question_const(constant)
    end

    # добавление вопросов по грузовым шинам или дискам
    if rand(1..5) % 4 == 0
      list_questions << question_const(list2.sample)
    end

    list_questions

  end

  def format_hash_question_html(hash_question)
    rezult = "<div itemscope='' itemprop='mainEntity' itemtype='https://schema.org/Question'>  "
    rezult += "<h4 itemprop='name'> "
    rezult += hash_question[:question]
    rezult += "</h4> "
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
    rezult += "<h3>Часто задаваемые вопросы (FAQ):</h3> "
    rezult += str
    rezult += "</div><br> "
    return rezult
  end

end