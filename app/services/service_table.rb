module ServiceTable
  include StringProcessingServices
  include StringProcessing
  include TextOptimization

  # Копирование таблицы, переменная - объект
  def copy_table_to_table_copy(model, model_copy)
    model.find_each do |rec|
      attributes = rec.attributes.except("id") # Исключаем атрибут идентификатора
      model_copy.create!(attributes)
    end
  end

  # Имя таблицы - текст!!!
  def copy_table_to_table_copy_if_empty(table, table_copy)
    model = table.classify.constantize
    model_copy = table_copy.classify.constantize

    if model_copy.count.zero?
      copy_table_to_table_copy(model, model_copy)
    end

  end

  # Находим и удаляем случайную запись
  # пример: find_and_destroy_random_record("Brand")
  def find_and_destroy_random_record(table)
    model = table.classify.constantize
    random_record = model.order("RANDOM()").first
    random_record&.destroy
    random_record
  end

  def duplicated_in_data_json?(file_path)
    # require 'json'

    # Предположим, что ваш файл находится в этом местоположении
    # file_path = 'path_to_your_file.json'

    # Разбираем JSON из файла
    data = JSON.parse(File.read(file_path))

    # Извлекаем значения "TextTitle"
    titles = data.values.map { |block| block["TextTitle"] }

    # Проверяем, уникальны ли значения "TextTitle"
    titles_are_unique = titles.uniq.length == titles.length

    if titles_are_unique
      puts 'Все значения TextTitle - unique'
      result = true
    else
      puts 'Некоторые значения TextTitle - дублированы'
      # Извлекаем значения "TextTitle"
      titles = data.values.map { |block| block["TextTitle"] }

      # Группируем по значениям и фильтруем, оставляя только те, которые встречаются более 1 раза
      duplicates = titles.group_by { |v| v }.select { |k, v| v.size > 1 }.keys

      duplicates.each do |duplicate|
        puts "Duplicate title: #{duplicate}"
      end
      result = false
    end
    result
  end

  def remove_empty_sentences(table)
    model = table.classify.constantize
    model.where(sentence: [nil, ""]).delete_all
    model.where(id_text: [nil, ""]).delete_all
  end

  def small_is_sentence?(original_text, min_count = 3)
    result = false
    # Создание временной копии исходного текста с заменой знаков препинания на пробелы
    text = original_text.gsub(/[,;:'"(){}\[\]<>]/, ' ')
    # Очистить каждое слово от знаков препинания и привести его к нижнему регистру
    words = text.split(' ').reject { |word| prepositions_conjunctions.include?(word.strip.downcase) }.uniq
    result = true if words.count <= min_count
    result
  end

  def replace_errors_size(table)
    # очистка таблиц от мусора после первой генерации текстов
    model = table.classify.constantize
    exclude_words = arr_name_brand_uniq
    arr_test = []
    i = 0
    model.find_each do |record|

      if record.sentence.include?("195/65R15")
        record.update(sentence: record.sentence.gsub("195/65R15", "[size]"))
      end
      if record.sentence.include?(" X:")
        record.update(sentence: record.sentence.gsub(" X:", " [size]:"))
      end


      if record &&
        record.sentence &&
        (record.sentence.include?("15-дюймов") ||
          record.sentence.include?("долла") ||
          record.sentence.include?("(R)15") ||
          record.sentence.include?("15\"") ||
          record.sentence.include?("55") ||
          record.sentence.include?("215")
        )
        record.destroy
      end


      if record.sentence.include?("(торговая марка)")
        record.update(sentence: record.sentence.gsub("(торговая марка)", ""))
      end

      if record.sentence.match?(/195|65|(\ |\")15|15 (-|дюймов)/)
        record.destroy
      end
      if record.sentence.match?(/\d{1,}\s*символ(|а|ов)|20\d{2}/)
        record.destroy
      end
      if record.sentence.match?(/\[((М|м)одель|(w|h|r)(|-))\]/)
        record.destroy
      end

      # проверка что строка без кириллицы
      if !(record.sentence.match?(/[а-яА-ЯёЁ]/))
        record.destroy
        i += 1
      end

      if percent_of_latin_chars(record.sentence, exclude_words) > 15
        record.destroy
      end

      if record.str_number != 0 # строка не заголовок
        # arr_test << record.sentence if small_is_sentence?(record.sentence)
        record.destroy if small_is_sentence?(record.sentence)
      end

    end
    puts "arr_test = = = #{arr_test}"
    puts "Количество удаленных записей:  #{i} "
    return i
  end

  def add_variants_record_to_table_sentence(record_sentence)
    # ВНИМАНИЕ = только первая строка для ошибочных заголовков.
    # обработка предложения  и добавление нового варианта в таблицу seo_content_text_sentence
    #========================================================
    select_number_table = 2 # номер таблицы с результатами seo_phrase_sentence - 2

    data_table_hash = {
      number_of_repeats_for_text: 1,
      number_of_repeats: 1,
      str_seo_text: record_sentence[:str_seo_text],
      str_number: record_sentence[:str_number],
      id_text: record_sentence[:id_text],
      type_text: record_sentence[:type_text],
      num_snt_in_str: record_sentence[:num_snt_in_str],
      check_title: 1
    }

    record_original = SeoContentText.find(record_sentence[:id_text])
    sentences = record_original[:str].split(/(?<=[.!?])\s+/)
    first_sentence = sentences.first
    puts "id_text = #{record_sentence[:id_text]}"
    puts "first_sentence = #{first_sentence}"
    txt = seo_phrase(first_sentence,
                     data_table_hash[:number_of_repeats],
                     record_sentence[:str_number] * 10 + record_sentence[:num_snt_in_str], # номер  для определения заголовок(0) или текст
                     select_number_table)

    arr_result = make_array_phrase(txt, 1)

    arr_to_table(arr_result, data_table_hash, select_number_table)

  end

  def repeat_sentences_generation
    i = 0
    counts_new = []
    counts = SeoContentTextSentence.group(:id_text, :num_snt_in_str).count
    counts.each do |(id_text, num_snt_in_str), count|

      if count < 25
        record_sentence = SeoContentTextSentence.where(id_text: id_text, num_snt_in_str: num_snt_in_str).limit(1).first
        number_of_repeats_for_text = 25 - count > 5 ? 2 : 1
        number_of_repeats = number_of_repeats_for_text == 1 ? 25 - count : (25 - count) / 2
        add_variants_record_to_table_sentence_for_all(record_sentence, number_of_repeats_for_text, number_of_repeats)

        # i += 1
        # break if i > 3
        # puts "id_text: #{id_text}; num_snt_in_str: #{num_snt_in_str}; count: #{count}"
        # puts "record === #{record_sentence.inspect}"
        # counts_new << record_sentence
      end
    end
    # puts "i: #{i}"
    # puts "counts_new ===== #{counts_new.inspect}"
  end

  def add_variants_record_to_table_sentence_for_all(record_sentence, number_of_repeats_for_text = 1, number_of_repeats = 1)
    # обработка предложения  и добавление нового варианта в таблицу seo_content_text_sentence
    #========================================================
    select_number_table = 2 # номер таблицы с результатами seo_phrase_sentence - 2

    data_table_hash = {
      number_of_repeats_for_text: number_of_repeats_for_text,
      number_of_repeats: number_of_repeats,
      str_seo_text: record_sentence[:str_seo_text],
      str_number: record_sentence[:str_number],
      id_text: record_sentence[:id_text],
      type_text: record_sentence[:type_text],
      num_snt_in_str: record_sentence[:num_snt_in_str],
      check_title: 2
    }

    data_table_hash[:number_of_repeats_for_text].times do

      txt = seo_phrase(record_sentence[:sentence],
                       data_table_hash[:number_of_repeats],
                       record_sentence[:str_number] * 10 + record_sentence[:num_snt_in_str], # номер  для определения заголовок(0) или текст
                       select_number_table)

      arr_result = make_array_phrase(txt, 1)
      arr_to_table(arr_result, data_table_hash, select_number_table)

    end

  end

  def replace_errors_title_sentence
    # Создаем выборку по заданным условиям
    selected_records = SeoContentTextSentence.where("str_number != 0 AND num_snt_in_str = 0 AND check_title = 0")
    i = 0

    # Выполняем метод для каждого элемента выборки
    selected_records.find_each(batch_size: 1000) do |record_sentence|
      # break if i > 3
      add_variants_record_to_table_sentence(record_sentence)
      # i += 1
      record_sentence.destroy
    end

    # puts "count = #{i}"
    # unique_count = SeoContentTextSentence.pluck(:str_seo_text).uniq.count
    # puts "Количество уникальных значений: #{unique_count}"
  end

  def add_sentence_ua
    # Добавление украинского текста (перевод с русского)
    # Создаем выборку по заданным условиям (записи без украинского текста)
    selected_records = SeoContentTextSentence.where("sentence_ua = ''").order(id: :asc)

    # Выполняем метод для каждого элемента выборки
    selected_records.find_each(batch_size: 1000) do |record_sentence|
      begin
        topics = "У меня есть предложение '#{record_sentence[:sentence]}'"
        topics += "\n Сделай перевод этого предложения на украинский язык"
        topics += "\n Все, что написано латинским шрифтом, нужно оставить без изменения"

        new_text = ContentWriter.new.write_seo_text_ua(topics, 3500)
        if new_text
          new_text = new_text['choices'][0]['message']['content'].strip
        end

        record_sentence.update(sentence_ua: new_text)
      rescue => e
        puts "Произошла ошибка: #{e.message}"
        next
      end
    end
  end

  def clear_trash_ua
    selected_records = SeoContentTextSentence.where("sentence_ua != ''")
    exclude_words = arr_name_brand_uniq
    lowercase_cyrillic_letters = 'а-яєїґіё'
    arr = []
    sentence_ua_updated_empty = ""

    selected_records.find_each(batch_size: 1000) do |record_sentence|

      if record_sentence[:sentence_ua].start_with?(' ')
        # Удаляем пробелы в начале строки
        sentence_ua_updated = record_sentence[:sentence_ua].lstrip
        record_sentence.update(sentence_ua: sentence_ua_updated)
        record_sentence.reload # Перезагрузка записи
      end

      first_char = record_sentence[:sentence_ua].strip[0]
      if first_char && lowercase_cyrillic_letters.include?(first_char)&&!record_sentence[:sentence_ua].start_with?('-')
        # Удаляем предложения, которые начинаются с маленькой буквы
        record_sentence.update(sentence_ua: sentence_ua_updated_empty)
        record_sentence.reload # Перезагрузка записи
        arr << record_sentence[:sentence_ua].strip # Вывод предложения, начинающегося с маленькой буквы
      end


      regex1 = "(П|п)ере(кл|вів)"
      regex2 = "(П|п)еревод"
      regex = "(" + regex1 +"|" + regex2 + ")"
      regex_dop = regex + "(|.+)(|\s+)(:|\'|\")"
      if record_sentence[:sentence_ua] =~ /#{regex}/
        sentence_ua_updated = record_sentence[:sentence_ua].gsub(/#{regex_dop}/, '')
        sentence_ua_updated =~ /#{regex}/ ? record_sentence.update(sentence_ua: sentence_ua_updated_empty) : record_sentence.update(sentence_ua: sentence_ua_updated)
        record_sentence.reload # Перезагрузка записи
      end

      regex1 = "(|Я)(|\s)(М|м)(аю|аємо|аючи)\sпропозицію" # Маємо пропозицію
      regex2 = "(У|у)\s((М|м)ен(е|я)|нас)\s(есть|є)\sпропозиція"
      regex3 = "(|(Ц|ц)е(|й))(|\s)(|(М|м)оє|моя)\sпропозиція"
      regex = "(" + regex1 +"|" + regex2 +"|" + regex3 + ")"
      regex_dop = regex + "(|.+)(|\s+)(:|\'|\")"
      if record_sentence[:sentence_ua] =~ /#{regex}/
        sentence_ua_updated = record_sentence[:sentence_ua].gsub(/#{regex_dop}/, '')
        sentence_ua_updated =~ /#{regex}/ ? record_sentence.update(sentence_ua: sentence_ua_updated_empty) : record_sentence.update(sentence_ua: sentence_ua_updated)
        record_sentence.reload # Перезагрузка записи
      end

      # проверка что строка без кириллицы
      if !!(record_sentence[:sentence_ua] =~ /\A[^а-яєїґіёА-ЯЄЇҐІЁ]*\z/)
        record_sentence.update(sentence_ua: sentence_ua_updated_empty)
        record_sentence.reload # Перезагрузка записи
      end

      if percent_of_latin_chars(record_sentence[:sentence_ua], exclude_words) > 15
        record_sentence.update(sentence_ua: sentence_ua_updated_empty)
        record_sentence.reload # Перезагрузка записи
      end

      if record_sentence[:str_number] != 0 # строка не заголовок
        record_sentence.update(sentence_ua: sentence_ua_updated_empty) if small_is_sentence?(record_sentence[:sentence_ua])
        record_sentence.reload # Перезагрузка записи
      end


      # убираем из текста кавычки
      if record_sentence[:sentence_ua] =~ /(\'|\")/
        sentence_ua_updated = record_sentence[:sentence_ua].gsub(/(\'|\")/, '')
        record_sentence.update(sentence_ua: sentence_ua_updated)
        record_sentence.reload # Перезагрузка записи
      end

    end

    puts "arr = = = = = #{arr.inspect}"
  end

  def arr_record_manufacturers
    manufacturers = ["Toyota", "Ford", "Volkswagen", "Honda", "Chevrolet", "BMW", "Mercedes-Benz", "Audi", "Hyundai", "Nissan",
                     "Fiat", "Renault", "Peugeot", "Citroen", "Volvo", "Skoda", "Seat", "Opel", "Mini", "Jaguar",
                     "Cadillac", "Jeep", "Dodge", "Chrysler", "Buick", "Tesla", "GMC", "Ram", "Lincoln", "Chevrolet"]

    conditions = manufacturers.map { |m| "sentence LIKE '%#{m}%'" }.join(" OR ")
    results = SeoContentTextSentence.where(conditions)

  end


  def arr_records_for_repeat_ua
    arr = ["15-дюймовый обод", "15-дюймовый диск", "15-дюймовые диски", "15-дюймовые обода",
           "15-дюймовые ободы", "15-дюймовый диаметр", "15\"", "(R)15"]

    conditions = arr.map { |m| "sentence LIKE '%#{m}%'" }.join(" OR ")
    results = SeoContentTextSentence.where(conditions)
  end

  def unload_to_xlsx (array_records,name, type = 0)
    @selected_records = array_records

    package = Axlsx::Package.new
    workbook = package.workbook

    workbook.add_worksheet(name: "Seo Content Text Sentences") do |sheet|
      # Заголовки колонок
      sheet.add_row ["ID", "Sentence",  "SentenceUA"]

      # Запись данных
      @selected_records.each do |record|
        sentence_ua = type == 0 ?  record.sentence_ua : "SentenceUA"
        sheet.add_row [record.id, record.sentence, sentence_ua]
      end
    end

    send_data package.to_stream.read, :filename => "seo_content_text_sentences_#{name}.xlsx", :type => "application/xlsx"

  end



end