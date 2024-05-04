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

  # def update_seo_content_text_sentence_id_text
  #   # Находим все записи, где id_text is null
  #   SeoContentTextSentence.where(id_text: nil).find_each do |sentence|
  #     # Находим соответствующую запись в SeoContentText
  #     seo_content_text = SeoContentText.find_by(content_type: sentence.str_seo_text)
  #
  #     # Обновляем id_text, если найдена соответствующая запись
  #     sentence.update(id_text: seo_content_text.id, type_text: seo_content_text.type_text) if seo_content_text
  #   end
  # end

  def update_seo_content_text_sentence_id_text
    SeoContentTextSentence.where(id_text: nil).find_each do |sentence|
      attempts = 0
      begin
        seo_content_text = SeoContentText.find_by(content_type: sentence.str_seo_text)

        if seo_content_text
          sentence.update(id_text: seo_content_text.id, type_text: seo_content_text.type_text)
        end
      rescue => e
        attempts += 1

        if attempts < 5
          sleep(2) # Wait for 2 seconds before retrying
          retry
        else
          puts "Failed to update record after 5 attempts. Error: #{e.message}"
        end
      end
    end
  end

  # Имя таблицы - текст!!!
  def copy_table_to_table_copy_if_empty(table, table_copy, max_retries = 5)
    model = table.classify.constantize
    model_copy = table_copy.classify.constantize

    begin
      retry_attempts ||= 0
      if model_copy.count.zero?
        copy_table_to_table_copy(model, model_copy)
      end
    rescue ActiveRecord::StatementInvalid => e
      if retry_attempts < max_retries
        retry_attempts += 1
        sleep(5) # Задержка на 5 секунд перед следующей попыткой
        retry
      else
        raise e # Если количество попыток превышает max_retries, выбросить исключение
      end
    end
  end

  # Находим и удаляем случайную запись
  # пример: find_and_destroy_random_record("Brand")
  def find_and_destroy_random_record(table)
    model = table.classify.constantize
    random_record = model.order("RANDOM()").first
    random_record&.destroy
    random_record
  rescue => e
    puts "Error occurred: #{e.message}"
    nil
  end

  def duplicated_in_data_json?(file_path)
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

  def delete_records_for_id
    array_id = [
      522427, 532670, 800703, 1207563,
      1207561, 1181327, 1207559, 429496,
      439716, 468878, 1078880, 386356,
      1086032, 1086005, 1198389, 1198395,
      1198403, 1058253, 1214936, 1214939, 1214946,
      1214949, 535581,
      517580, 517583, 836485, 836487, 1050763, 1050764,
      517581, 517584, 1164660, 1164661, 1152812

    ]
    array_id.each do |id|
      SeoContentTextSentence.destroy_by(id: id)
    end

    SeoContentTextSentence.where("sentence like ? ", "%копирайт%").delete_all

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
        (
          record.sentence.include?("15-дюймов") ||
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

  # ====================Для дисков ============================
  def replace_errors_sentence_diski(table)
    # очистка таблиц от мусора после первой генерации текстов в дисках
    model = table.classify.constantize
    exclude_words = arr_name_brand_uniq
    arr_test = []
    i = 0
    j = 0
    records = model.where("id_text > ?", 35400)
    # records = model.where("id_text >= ? and id_text <= ?", 50242, 50400) # - тест по заменам
    # records = model.where("id_text = ?", 50242) # - тест по заменам

    regexp = Regexp.new(AUTO_MANUFACTURES.join("|"), Regexp::IGNORECASE)
    brands = Brand.where(type_url: 0).pluck(:name) # !!! для дисков - массив для удаления строк с шинными брендами !!!
    brand_regex = /\b(#{brands.join('|')})\b/

    records.find_each do |record|
      replace_mark_in_string(record) # обновление записей с ошибками

      if record &&
        record.sentence &&
        (
          !(record.sentence.match?(/[а-яА-ЯёЁ]/)) ||
            record.sentence.match?(/\s[A-QS-Z]\s/) ||
            record.sentence.match?(regexp) ||
            record.sentence.match?(brand_regex) ||
            record.sentence.match?(/(^|\s)(я|мой|моего|моя|мою)\s/i) ||
            record.sentence.match?(/google|Rolex|Casio|Louis|Vuitton|Chronos|PremiumWatches|Huawei|Tag|Heuer|Swatch|часы|часов/i) ||
            record.sentence.match?(/Nike|Puma|Adidas|ABC|Xiaomi|Sony|Bose|Bravia|Rocher|Domino|Jamie|Bosch|Delizioso|Cordon|Tefal|Camry|Starbucks|iPhone|Lauder/i) ||
            record.sentence.match?(/LuxDeco|BoConcept|Luxury|Art|Calvin|Christian|Dior|YZL|Louboutin|Jimmy|Levi|Craft|Eichholtz|IKEA|Gucci|Prada|land/i) ||
            record.sentence.match?(/McDonald|Trend|Samsung|LG|Nikon|Spotify|Apple|Chanel|Coca|Nutella|Bella|LuxInteriors|Eichholtz/i) ||
            record.sentence.match?(/одежд|копир|контент|мебел|кожа|двигател|мотор|кроссовк|туфл|рестор|реклам|интерьер|овощ/i) ||
            record.sentence.match?(/макияж|маникюр|космети|кож(е|а|у|ей)|крем(а|у|ом|ов)|сумк|женщи|парфюм|аромат|закус|напит|к(а|о)фе|волос/i) ||
            record.sentence.match?(/колье|шарф|перчат|рюкзак|телевизор|рубаш|сипед|джинс|смартфон|прогулк/i) ||
            record.sentence.match?(/футбол|клуб|трениров|фитнес|питани|кулинар|кухн|сковород|экран|Видео|гаджет|наушник|звучани|аудио/i) ||
            record.sentence.match?(/\bтрек(|и|а|ов|ами|ом)\b/i) ||
            record.sentence.match?(/\bблюд(|а|у|ами|ом|о|е)\b/i) ||
            record.sentence.match?(/\bужин\b/i) ||
            record.sentence.match?(/поисков(ая|е|ых|ого)\s(систем|продвиж|выдач)/i) ||

            record.sentence.match?(/(|автомобильн(ому|ым|ом|ый)\s)салон(|а|у|ом|е)\sкрасоты|(^|\s)(литр|музык|компакт-диск|((кон|)текст(?!\w*ур)))/i) ||
            record.sentence.match?(/(стильн(ые|ую)|уличную|Утепленная|Элегантная|Качественная|представлена|Подбирайте|Эксклюзивная|идеальную)\sобувь/i) ||
            record.sentence.match?(/(^|\s)(кон|)текст(?!\w*ур)/i) ||
            record.sentence.match?(/\b\w{21,}\b/) ||

            percent_of_latin_chars(record.sentence, exclude_words) > 15
        )

        # record.destroy
        # i += 1
        #==================================

        attempts = 0

        begin
          record.destroy!
          i += 1
        rescue ActiveRecord::RecordNotDestroyed => e
          attempts += 1
          if attempts <= 3
            puts "Попытка номер #{attempts} удаления записи #{record.id} не удалась: #{e}. Повторяю..."
            retry
          else
            puts "3 попытки удаления записи #{record.id} не удалась: #{e}. Пропускаю..."
            j +=1
          end
        end



        #====================================
      end

    end
    result = "Количество удаленных записей:  #{i} |   Удаление не удалось : #{j} "
    puts result
    return result
  end

  def replace_mark_in_string(record)
    marks = MARKS
    if record.sentence.match?(/лит(|е)ц/i)
      marks.each do |mark, template|
        if record.sentence.match?(/#{mark}/i)
          new_str = record.sentence.gsub(/\b#{mark}\b/i, template).capitalize
          record.update(sentence: new_str)
        end
      end
    end
    if record.sentence.match?(/Black Rhino Overland/i)
      new_str = record.sentence.gsub(/Black Rhino Overland/i, "").capitalize
      record.update(sentence: new_str)
    end
  end

  # ===========================================================

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

  def clear_trash_brand
    selected_records = SeoContentTextSentence.where("LOWER(sentence) like ? or LOWER(sentence_ua) like ?", "%[brand]%", "%[brand]%")

    selected_records.each do |record_sentence|

      if record_sentence.sentence =~ /от \[brand\]/i
        sentence_updated = record_sentence.sentence.gsub(/от \[brand\]/i, '')
        record_sentence.update(sentence: sentence_updated)
      end
      if record_sentence.sentence_ua =~ /від \[brand\]/i
        sentence_ua_updated = record_sentence.sentence_ua.gsub(/від \[brand\]/i, '')
        record_sentence.update(sentence_ua: sentence_ua_updated)
      end

      if record_sentence.sentence =~ /, как \[brand\],/i
        sentence_updated = record_sentence.sentence.gsub(/, как \[brand\],/i, ' ')
        record_sentence.update(sentence: sentence_updated)
      end
      if record_sentence.sentence_ua =~ /, як \[brand\],/i
        sentence_ua_updated = record_sentence.sentence_ua.gsub(/, як \[brand\],/i, ' ')
        record_sentence.update(sentence_ua: sentence_ua_updated)
      end

      # record_sentence.reload # Перезагрузка записи
      if record_sentence.sentence =~ /\[brand\]/i
        sentence_updated = record_sentence.sentence.gsub(/\[brand\]/i, ' ')
        record_sentence.update(sentence: sentence_updated)
      end
      if record_sentence.sentence_ua =~ /\[brand\]/i
        sentence_ua_updated = record_sentence.sentence_ua.gsub(/\[brand\]/i, ' ')
        record_sentence.update(sentence_ua: sentence_ua_updated)
      end
      # record_sentence.reload # Перезагрузка записи

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
      if first_char && lowercase_cyrillic_letters.include?(first_char) && !record_sentence[:sentence_ua].start_with?('-')
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

    # puts "arr = = = = = #{arr.inspect}"
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

  def delete_records_with_instructions
    arr = []
    arr1 = ["Дайте", "Создайте", "Предложение"]
    conditions1 = arr1.map { |m| "sentence LIKE '%#{m}%'" }.join(" OR ")
    arr2 = (1..25).to_a
    conditions2 = arr2.map { |m| "sentence LIKE '%#{m}%'" }.join(" OR ")
    conditions = "(" + conditions1 +") AND (" + conditions2 + ")"

    results = SeoContentTextSentence.where(conditions)
    results.each do |el|
      el.destroy
    end

    results = SeoContentTextSentence.where("sentence like '%фраз%'")
    results.each do |el|
      el.destroy
    end

    # if record.sentence.match?(/Предложение \d+/)
    #   arr << el.sentence
    #   # record.destroy
    # end

    puts arr.inspect
  end

  def unload_to_xlsx (array_records, name, type = 0)
    @selected_records = array_records

    package = Axlsx::Package.new
    workbook = package.workbook

    workbook.add_worksheet(name: "Seo Content Text Sentences") do |sheet|
      # Заголовки колонок
      sheet.add_row ["ID", "Sentence", "SentenceUA"]

      # Запись данных
      @selected_records.each do |record|
        sentence_ua = type == 0 ? record.sentence_ua : "SentenceUA"
        sheet.add_row [record.id, record.sentence, sentence_ua]
      end
    end

    send_data package.to_stream.read, :filename => "seo_content_text_sentences_#{name}.xlsx", :type => "application/xlsx"

  end

  def proc_import_text_ua(proc)
    #  ручное импортирование данных в таблицы базы данных
    # в lib/text_ua должны находится файлы только для одной загрузки!!!

    path = Rails.root.join('lib', 'text_ua', '*.xlsx')
    j = 0
    result = 0
    Dir.glob(path).each do |filename|
      j += import_text_ua(filename) if proc == 1 # для таблицы SeoContentTextSentence
      j += import_questions_ua(filename) if proc == 2 # для таблицы QuestionsBlock
      result += 1
    end
    return {str: j, files: result}
  end

  def import_text_ua(filename)
    # Заполнение таблицы с текстом по ошибкам
    # lib/text_ua/seo_content_text_sentences_20240412170218.xlsx

    # excel_file = "lib/text_errors.xlsx"
    excel = Roo::Excelx.new(filename)
    i = 0
    excel.each_row_streaming(pad_cells: true) do |row|
      begin
        i += 1
        id = row[0]&.value
        sentence = row[1]&.value
        sentence_ua = row[2]&.value
        sentence_ua = sentence_ua.gsub("​​", '') if sentence_ua.present?
        sentence_ua_updated = SeoContentTextSentence.find_by_id(id)
        sentence_ua_updated.update(sentence: sentence, sentence_ua: sentence_ua) if sentence_ua.present? && !sentence_ua_updated.nil?
      rescue StandardError => e
        puts "Error on row #{i}: #{e.message}"
        next
      end
    end
    return i

  end

  def import_questions_ua(filename)
    # Заполнение таблицы с текстом по вопросам
    # lib/text_ua/seo_question_ru_track.xlsx

    excel = Roo::Excelx.new(filename)
    i = 0
    excel.each_row_streaming(pad_cells: true) do |row|
      begin
        i += 1
        id = row[0]&.value
        question_ua = row[3]&.value
        answer_ua = row[4]&.value
        question_ua = question_ua.gsub("​​", '')
        answer_ua = answer_ua.gsub("​​", '')

        sentence_ua_updated = QuestionsBlock.find_by_id(id)
        sentence_ua_updated.update(question_ua: question_ua, answer_ua: answer_ua)
      rescue StandardError => e
        puts "Error on row #{i}: #{e.message}"
        next
      end
    end
    return i

  end

end