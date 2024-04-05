module ServiceTable
  include StringProcessingServices
  include StringProcessing

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
    # replace_size_to_template(str)

  end

  def replace_errors_size(table)
    # очистка таблиц от мусора после первой генерации текстов
    model = table.classify.constantize
    exclude_words = arr_name_brand_uniq
    i = 0
    model.find_each do |record|
      if record.sentence.include?("195/65R15")
        record.update(sentence: record.sentence.gsub("195/65R15", "[size]"))
      end
      if record.sentence.include?(" X:")
        record.update(sentence: record.sentence.gsub(" X:", " [size]:"))
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

      # Аккуратно с заголовками
      # if record.sentence.match?(/\:/) && record.str_number > 0
      #   record.destroy
      #   # i +=1
      # end

      # проверка что строка без кириллицы
      if !(record.sentence.match?(/[а-яА-ЯёЁ]/))
        record.destroy
      end
      if percent_of_latin_chars(record.sentence, exclude_words) > 15
        puts record.sentence
        puts "percent_of_latin_chars(text) -15- #{percent_of_latin_chars(record.sentence, exclude_words)}"
        record.destroy
      end

    end
    # puts "Количество удаленных зарисей:  #{i} "
  end

  def repeat_sentences_generation(table)
    i = 0
    model = table.classify.constantize
    counts = model.group(:id_text, :num_snt_in_str).count
    counts.each do |(id_text, num_snt_in_str), count|
      if count < 5
        puts "id_text: #{id_text}; num_snt_in_str: #{num_snt_in_str}; count: #{count}"
        record_sentence = model.where(id_text: id_text, num_snt_in_str: num_snt_in_str).limit(1).first
        puts "record === #{record_sentence.inspect}"
        add_variants_record_to_table_sentence(record_sentence)
        i += 1
      end
    end
    puts "i: #{i}"
  end

  def add_variants_record_to_table_sentence(record_sentence)
    # обработка предложения - таблица seo_content_text_sentence
    #========================================================
    select_number_table = 2 # номер таблицы с результатами seo_phrase_sentence - 2

    data_table_hash = {
      number_of_repeats_for_text: 1,
      number_of_repeats: 1,
      str_seo_text: record_sentence[:str_seo_text],
      str_number: record_sentence[:str_number],
      id_text: record_sentence[:id_text],
      type_text: record_sentence[:type_text],
      num_snt_in_str: record_sentence[:num_snt_in_str]
    }

    txt = seo_phrase(record_sentence[:sentence],
                     data_table_hash[:number_of_repeats],
                     record_sentence[:str_number] * 10 + record_sentence[:num_snt_in_str],
                     select_number_table)

    arr_result = make_array_phrase(txt, 1)

    arr_to_table(arr_result, data_table_hash, select_number_table)

  end

  def replace_errors_title_sentence
    # Создаем выборку по заданным условиям
    selected_records = SeoContentTextSentence.where("str_number != 0 AND num_snt_in_str = 0 AND check_title = 0")
    i = 0

    # Выполняем метод для каждого элемента выборки
    selected_records.find_each(batch_size: 1000) do |record_sentence|
      break if i > 3
      add_variants_record_to_table_sentence(record_sentence)
      i += 1
      record_sentence.destroy
    end

    puts "count = #{i}"

    unique_count = SeoContentTextSentence.pluck(:str_seo_text).uniq.count
    puts "Количество уникальных значений: #{unique_count}"
  end

end