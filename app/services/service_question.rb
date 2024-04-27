# app/services/service_question.rb
module ServiceQuestion
  include ServiceQustitionProcessing
  include StringProcessing

  def all_questions_for_page(count_limit_size = 3)
    list_questions = []
    type_season = type_for_url_shiny % 10

    # отбираются вопросы по типу урла - url_type_by_parameters
    if type_season == 0
      questions = QuestionsBlock.where(type_paragraph: url_type_by_parameters).order("RANDOM()").limit(count_limit_size)
    else
      questions = QuestionsBlock.where(type_paragraph: url_type_by_parameters, type_season: type_season).order("RANDOM()").limit(count_limit_size)
    end

    questions = filter_questions(questions)

    questions.each do |record|
      hash = url_type_ua? ? { question: record[:question_ua], answer: record[:answer_ua] } : {  question: record[:question_ru], answer: record[:answer_ru] }
      list_questions << hash
    end


    # добавляем еще 1-4 вопроса по константам
    list_questions += questions_dop([CITIES, BRANDS, DIAMETERS, TOP_SIZE],
                                    [DIAMETERS_TRUCK, BRANDS_TRUCK, SIZE_TRUCK, DIAMETERS_WHEELS, BRANDS_WHEELS])


    result = format_question_full(list_questions)

    # puts result
    result
    # render json: { list_questions: result }

    # =========================================================
    # ============================================================
  rescue => e
    puts "Error occurred: #{e.message}"
    nil
  end


  def filter_questions(questions)
    puts "questions =  #{questions.inspect}"
    filtered_questions = questions.dup.to_a # преобразуем ActiveRecord::Relation в Array
    puts "filtered_questions 1 =  #{filtered_questions.inspect}"
    filtered_questions.each_with_index do |question1, index1|
      words1 = question1.question_ru.downcase.split.map { |word| 2.times { word.chop! }; word }
      puts "words1 =  #{words1.inspect}"
      filtered_questions.reject! do |question2|
        puts "question1 =  #{words1.inspect}"
        puts "question2 =  #{words1.inspect}"
        next if question1 == question2
        words2 = question2.question_ru.downcase.split.map { |word| 2.times { word.chop! }; word }
        common_words = words1 & words2
        common_words.size >= 5
      end
    end
    puts "filtered_questions =  #{filtered_questions.inspect}"
    filtered_questions
  end

  def first_filling_of_table(type_paragraph = 0, count = 0,  type_season = 1)
    # Заполнение таблицы с текстом по ошибкам
    # type_paragraph: 0 - по легковым шинам
    # type_season: 1 - летние

    excel_file = "lib/text_questions/questions_base.xlsx"
    excel = Roo::Excelx.new(excel_file)
    i = 1
    excel.each_row_streaming(pad_cells: true) do |row|
      break if i >= count && count > 0
      begin
        question = row[0]&.value
        question = question.gsub("​​", '') if question.present?
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

  def second_filling_of_table(type_paragraph, count_repeat = 5 )
    # Определение количества строк в файле Excel
    excel_file = "lib/text_questions/questions_base.xlsx"
    excel = Roo::Excelx.new(excel_file)
    count = excel.last_row
    puts "количесто строк в ексель: #{count}"

    # count = 2 # тестовое значение - удалить
    # Выбор первых "count" записей из таблицы
    records = QuestionsBlock.where(type_paragraph: type_paragraph).limit(count)

    count_repeat.times do
      # 1 - летние, 2 - зимние, 3 - всесезонные
      (1..3).each do |season|
        records.each do |record|
          rewrite_question_and_answer(record[:question_ru], season, type_paragraph)
        end
      end
    end

  rescue => e
    puts "Error occurred: #{e.message}"
    nil

  end

  def rewrite_question_and_answer(question, season, type_paragraph = 0)
    # Делается рерайт полученного случайного вопроса
    # перевод на украинский делается отдельно
    if type_paragraph == 0
      str_season = case season
                   when 1
                     "летних шин"
                   when 2
                     "зимних шин"
                   when 3
                     "всесезонных шин"
                   else
                     ""
                   end
    end
    if type_paragraph == 2
      str_season = case season
                   when 1
                     "грузовых шин, используемых на прицепах"
                   when 2
                     "грузовых рулевых шин"
                   when 3
                     "грузовых ведущих шин"
                   else
                     ""
                   end
    end

    topics = "Сделайте, пожалуйста, еще один вариант этого вопроса для #{str_season}: #{question}."
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