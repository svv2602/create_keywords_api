# app/services/service_qustition_processing.rb
module ServiceQustitionProcessing
  include ServiceTable
  include Constants
  include StringProcessing

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

    # Делается рерайт полученного случайного вопроса
    topics = "Сделай, желательно одним предложением, краткий рерайт вопроса: #{question}."

    question = ContentWriter.new.write_draft_post(topics, 150)['choices'][0]['message']['content'].strip
    # Убирем лишний текст после знака вопроса
    question = question.split("?").first

    # Получение ответа на вопрос
    topics = "Дай краткий ответ, не более 300 печатных символов, на вопрос: #{question}."
    answer = ContentWriter.new.write_draft_post(topics, 500)
    answer = answer['choices'][0]['message']['content'].strip

    rezult = { question: question, answer: answer }

  rescue => e
    puts "Error occurred: #{e.message}"
    nil

  end

  def sinonim(str)
    if url_type_ua?
      rand(0..20) % 2 ? str = "Використовуючи замість слова 'шини' синоніми, такі, наприклад, як: 'гума' або 'колеса' #{str.downcase} " : str
    else
      rand(0..20) % 2 ? str = "Используя вместо слова 'шины' синонимы, такие, например, как: 'резина' или 'колеса' #{str.downcase} " : str
    end
    str
  end

  def question_const(el)

    if url_type_ua?
      question_random = el[:questions_ua].sample
      topics = sinonim(", зроби одним реченням короткий рерайт питання: #{question_random[:question_ua]}.")
      if el.has_key?(:aliases_ua)
        field_aliases = "aliases_ua"
        field_name = "name_ua"
      else
        field_aliases = "aliases"
        field_name = "name"
      end
    else
      question_random = el[:questions].sample
      topics = sinonim(", сделай одним предложением краткий рерайт вопроса: #{question_random[:question]}.")
      field_aliases = "aliases"
      field_name = "name"
    end
    answer = ""

    question = ContentWriter.new.write_draft_post(topics, 150)['choices'][0]['message']['content'].strip

    el[field_aliases.to_sym].size < 10 ? max = el[field_aliases.to_sym].size : max = 10
    random_brands = el[field_aliases.to_sym].sample(rand(6..max)) # случайное количество ответов
    # сборка в ответ элементов массива
    random_brands.each_with_index do |el, i|
      puts " field_aliases = #{el[field_aliases.to_sym]},  field_name = #{el[field_name.to_sym]}"
      puts " question_random = #{question_random.inspect}"
      answer += "<a href='#{question_random[:url]}#{el[:alias]}'>• #{el[field_name.to_sym]}  </a>    "
    end
    answer = answer.gsub("prokoleso.ua", "prokoleso.ua/ua") if rand(1..10) % 2 == 0
    rezult = { question: question, answer: "[#{answer}]" }
  end

  def questions_dop(list1, list2)

    # формирование количяества доп вопросов
    list_questions = []
    arr = list1.sample(2)

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
    rezult = ''
    if hash_question && hash_question.key?(:question) && hash_question.key?(:answer)
      rezult = "<div itemscope='' itemprop='mainEntity' itemtype='https://schema.org/Question'>  "
      rezult += "<h4 itemprop='name'> "
      # Убирем лишний текст после знака вопроса

      field_question = "question"
      question = hash_question[field_question.to_sym].split("?").first
      rezult += gsub_symbol(question)
      rezult += "</h4> "
      rezult += "<div itemprop='acceptedAnswer' itemscope='' itemtype='https://schema.org/Answer'> "
      rezult += "<p itemprop='text'> "
      rezult += gsub_symbol(hash_question[:answer])
      rezult += "</p> "
      rezult += "</div> "
      rezult += "</div> "
      rezult = "" if rezult =~ /<h4 itemprop='name'>\s*<\/h4>/
    end

    return rezult
  end

  def gsub_symbol(str)
    url_params = url_shiny_hash_params
    str_new = str
    if str && !str.empty?
      if str !~ /(• )/
        str_new = str.downcase
                     .gsub('#', '')
                     .gsub(/\u003c(\/|)h\d\u003e/, '')
                     .gsub(/<(\/|)h\d>/, '')
                     .gsub(/\n.+/, '')
                     .gsub('заголовок:', '')
                     .gsub('микроразметка:', '')
                     .gsub('seo-текст:', '')
                     .gsub('основной текст:', '')
                     .gsub('украин', 'Украин')
                     .gsub('введение:', '')
                     .gsub('[', '')
                     .gsub(']', '')
                     .gsub(/(|\/)html/, '')
                     .gsub('*', '')
                     .gsub(/195\/65(R|r)15/, replace_name_size(url_params))

        # Разбить строку на предложения
        sentences = str_new.split(". ")
        # Преобразовать первые буквы каждого предложения в заглавные буквы
        capitalized_sentences = sentences.map(&:capitalize)
        # Объединить предложения в строку снова
        str_new = capitalized_sentences.join(". ")

      end

      str_new = str_new.gsub('[', '')
                       .gsub(']', '')

      if str_new =~ /\A(|\s+)(\w|[а-яА-Я])/
        str_new = str_new.gsub(/\A(|\s+)(\w|[а-яА-Я])/) { $1 + $2.capitalize }
      end
    else
      str_new = ''
    end

    str_new
  end

  def format_hash_question_with_head_html(str)
    rezult = "<div itemscope='' itemtype='https://schema.org/FAQPage'>  "
    str_ua = url_type_ua? ? "Поширені запитання (FAQ)" : "Часто задаваемые вопросы (FAQ)"
    rezult += "<h3>#{str_ua}:</h3> "
    rezult += str
    rezult += "</div><br> "
    return rezult
  end

end