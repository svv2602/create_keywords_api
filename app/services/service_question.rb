# app/services/service_question.rb
module ServiceQuestion
  include ServiceQustitionProcessing
  include StringProcessing

  def all_questions_for_page
    list_questions = []
    type_season = type_for_url_shiny % 10

    puts type_for_url_shiny
    puts type_season

    if type_season == 0
      questions = QuestionsBlock.where(type_paragraph: 0).order("RANDOM()").limit(2)
    else
      questions = QuestionsBlock.where(type_paragraph: 0, type_season: 0).order("RANDOM()").limit(2)
    end

    questions.each do |record|
      hash = url_type_ua? ? { question: record[:question_ua], answer: record[:answer_ua] } : { question: record[:question_ru], answer: record[:answer_ru] }
      list_questions << hash
    end

    # добавляем еще 1-4 вопроса по константам
    list_questions += questions_dop([CITIES, BRANDS, DIAMETERS, TOP_SIZE],
                                    [DIAMETERS_TRUCK, BRANDS_TRUCK, SIZE_TRUCK, DIAMETERS_WHEELS, BRANDS_WHEELS])

    result = format_question_full(list_questions)
    puts result
    result
    # render json: { list_questions: result }

    # =========================================================
    # ============================================================
  rescue => e
    puts "Error occurred: #{e.message}"
    nil
  end

  def first_filling_of_table(count = 0, type_paragraph = 0, type_season = 1)
    # Заполнение таблицы с текстом по ошибкам
    # type_paragraph: 0 - по легковым шинам
    # type_season: 0 - летние

    excel_file = "lib/text_questions/questions_base.xlsx"
    excel = Roo::Excelx.new(excel_file)
    i = 1
    excel.each_row_streaming(pad_cells: true) do |row|
      break if i >= count && count > 0
      begin
        question = row[0]&.value
        question = question.gsub("​​", '')
        # Получение ответа на вопрос
        topics = " #{question}. \nOтветь на этот вопрос кратко, максимум двумя предложениями."
        answer = ContentWriter.new.write_draft_post(topics, 500)
        answer = answer['choices'][0]['message']['content'].strip

        QuestionsBlock.find_or_create_by(question_ru: question,
                                         answer_ru: answer,
                                         type_paragraph: type_paragraph,
                                         type_season: type_season) if question.present?
      rescue StandardError => e
        puts "Error on row #{i}: #{e.message}"
        next
      end
      i += 1
    end
  end

  def second_filling_of_table(count_repeat)
    # Определение количества строк в файле Excel
    excel_file = "lib/text_questions/questions_base.xlsx"
    excel = Roo::Excelx.new(excel_file)
    count = excel.last_row
    puts "количесто строк в ексель: #{count}"

    # count = 2 # тестовое значение - удалить
    # Выбор первых "count" записей из таблицы
    records = QuestionsBlock.limit(count)

    count_repeat.times do
      # 1 - летние, 2 - зимние, 3 - всесезонные
      (1..3).each do |season|
        records.each do |record|
          rewrite_question_and_answer(record[:question_ru], season, 0)
        end
      end
    end


  rescue => e
    puts "Error occurred: #{e.message}"
    nil

  end

  def rewrite_question_and_answer(question, season, type_paragraph = 0)
    # Делается рерайт полученного случайного вопроса
    str_season = case season
                 when 1
                   "летних"
                 when 2
                   "зимних"
                 when 3
                   "всесезонных"
                 else
                   ""
                 end

    topics = "Сделайте, пожалуйста, еще один вариант этого вопроса для #{str_season} шин: #{question}."
    topics += "\nВ ответ не включай собственные комментарии"

    question = ContentWriter.new.rewrite_question(topics, 150)['choices'][0]['message']['content'].strip
    # Убирем лишний текст после знака вопроса
    question = question.split("?").first
    question = question.gsub(/[[:punct:]]+$/, '')
    question += "?" unless question.end_with?("?")

    # Получение ответа на вопрос
    topics = " #{question}. \nДайте, пожалуйста, ответ на этот вопрос кратко, максимум двумя предложениями."
    answer = ContentWriter.new.rewrite_question(topics, 500)
    answer = answer['choices'][0]['message']['content'].strip
    QuestionsBlock.find_or_create_by(question_ru: question, answer_ru: answer, type_paragraph: type_paragraph, type_season: season)

  rescue StandardError => e
    puts "Error: #{e.message}"
    return
  end

end