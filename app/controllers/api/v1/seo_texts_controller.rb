# app/controllers/api/v1/seo_texts_controller.rb
require 'benchmark'

class Api::V1::SeoTextsController < ApplicationController
  include StringProcessing
  include StringErrorsProcessing
  include TextOptimization
  include StringProcessingServices
  include ServiceTable

  def mytest
    # curl http://localhost:3000/api/v1/mytest?url=https%3A%2F%2Fprokoleso.ua%2Fshiny%2Fletnie%2Fkumho%2Fw-175%2Fh-70%2Fr-13%2F
    text = " size [size] size  моС size летние. [size] летние моСк овский покрышки R18 Kumho, HANKOOK отличает прочная конструкция. И я,апаппа. летние моСковский покрышки R18 Kumho, HANKOOK"

    result = remove_small_sentences(text, min_count = 3)
    puts "Все сделано! =====  #{result.inspect}"
    render json: { result: result }
  end

  def total_generate_seo_text

    # Первоначальное заполнение таблиц с текстами
    # Перенос первоначальных текстов в json

    txt_file_to_json

    file_path = Rails.root.join('lib', 'template_texts', 'data.json')
    if duplicated_in_data_json?(file_path)
      # # первый рерайт текстов по абзацам _
      # #===========================================================
      # # ВНИМАНИЕ!!!
      # #===========================================================
      # # для полной обработки набирать с параметром params[:type_proc] = 1
      # # пример: curl http://localhost:3000/api/v1/total_generate_seo_text?type_proc=0
      # # В total_arr_to_table, иначе обработке файла data.json - будет неполной
      # #===========================================================

      # total_arr_to_table(5, 5)
      # # удаление мусорных записей с латиницей и др
      # второй рерайт текстов по предложениям

      # total_arr_to_table_sentence(5, 5)
      # Итоговое удаление записей с несанкционированной ))) латиницей и россией
      # delete_all_trash_records_ai - переработать
    end

    replace_errors_title_sentence_duplicate

    puts "Все сделано!"
    render json: { result: "Все сделано!" }

  end


  def replace_errors_title_sentence_duplicate
    # задвоено - оригинал в service_table
    # перезаполнение title
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

  def json_write_for_read
    # Из текстового файла создает файл json с массивом строк, для дальнейшей подготовки к обработке
    # для запуска: внести текст, для обработки в файл lib/template_texts/data.txt

    txt_file_to_json
    # clear_size_temp # для обновления данных в таблице
    render json: { result: "Создан файл lib/template_texts/data.json" }
    # после обработки готовый файл нужно перенести в папку finished_texts
  end

  def raw_text
    # пример:
    # curl http://localhost:3000/api/v1/seo_text?url=https%3A%2F%2Fprokoleso.ua%2Fshiny%2Fletnie%2Fkumho%2Fw-175%2Fh-70%2Fr-13%2F
    result = ''

    arr_size = arr_size_to_error
    alphanumeric_chars_count = 0
    general_array_without_season = general_array_without_seasonality.shuffle
    puts "common_items - #{general_array_without_season.inspect}"

    # alphanumeric_chars_count_for_url_shiny - метод для определения базового количества символов в зависимости от урла
    min_chars = alphanumeric_chars_count_for_url_shiny

    while alphanumeric_chars_count < min_chars && general_array_without_season.any?
      content_type = general_array_without_season.first
      general_array_without_season = general_array_without_season.drop(1)

      result += generator_text(content_type) + "\n"
      arr = arr_size.shift(5)
      result += min_errors_text(arr) if size_present_in_url?

      alphanumeric_chars_count = result.scan(/[\p{L}\p{N}]/).length
    end

    # добавление текста по сезону

    # ================= content_type = general_array_with_seasonality.first =====================
    # Добавить условие в зависимости от урла по сезонности (нужен ли текст вообще?)
    # +++++++++++++++++++++++++++++++++++++++++++++
    # ========================================
    content_type = general_array_with_seasonality.first
    result += generator_text(content_type) + "\n"

    # удаляем похожие предложения
    result = similar_sentences_delete(result)

    # Добавление текста об ошибках в зависимости от диаметра колес, если в url есть размер
    if size_present_in_url?
      result += print_errors_text? ? arr_url_result_str : min_errors_text(arr_size)
    end

    # убираем лишние знаки пунктуации
    result = standardization_of_punctuation(result)

    # # Добавляем ссылки: - - -  перенесено в  seo_text - - - - - - - - -
    # insert_brand_url(result) if !size_only_brand_in_url?
    # result = insert_season_url_new(result)
    #
    # result = generate_title_h2 + result + "<br>"
    # result = result.gsub(/\s+/, ' ')
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    result
  end

  def min_errors_text(arr_size)
    result = ''
    if !print_errors_text? && !arr_size.empty?
      text_err = "<br>\n"
      text_err += "<p class='keywords-size'>"
      text_err += TEMPLATE_TEXT_ERROR.shuffle.first + " " + arr_size.shift(5).join(', ')
      text_err += "</p><br>\n"
      result += text_err
    end
    result
  end

  def seo_text

    result = replace_trash(raw_text)

    alphanumeric_chars_count = result&.scan(/[\p{L}\p{N}]/)&.length
    puts "количество значимых символов - #{alphanumeric_chars_count}"
    puts "Было:" + "=" * 80
    puts adjust_keyword_stuffing(result)
    result = replace_text_by_hash(result)
    result = replace_text_by_hash_minus(result)

    puts "Стало:" + "=>" * 40

    # Добавляем ссылки:
    insert_brand_url(result) if !size_only_brand_in_url?
    result = insert_season_url_new(result)

    result = generate_title_h2 + result + "<br>"
    result = result.gsub(/\s+/, ' ')

    puts adjust_keyword_stuffing(result)
    puts result
    render json: { result: result }

  end

  def general_array_without_seasonality
    # подбор текстов по урлу
    # переписать потом, если надо будет убрать еще типы статей для разных урлов,
    # сделать вначале отбор записей таблицы, а потом отбор по сезонам и .pluck

    if (10..14).include?(type_for_url_shiny)
      # puts "Значение в диапазоне от 10 до 14"
      # убираем статьи с сезоном и ассортиметом для брендов

      unique_type_texts = SeoContentText.where("type_text NOT LIKE ? AND type_text NOT LIKE ? AND type_text NOT LIKE ? AND type_text NOT LIKE ? AND type_text NOT LIKE ?",
                                               "%season%", "%letnie%", "%zimnie%", "%vsesezonie%", "%ассортимент%")
                                        .pluck(:type_text)
                                        .uniq
    else
      # puts "Значение вне диапазона от 10 до 14"
      # просто убираем статьи с сезоном
      unique_type_texts = SeoContentText.where("type_text NOT LIKE ? AND type_text NOT LIKE ? AND type_text NOT LIKE ? AND type_text NOT LIKE ?",
                                               "%season%", "%letnie%", "%zimnie%", "%vsesezonie%")
                                        .pluck(:type_text)
                                        .uniq
    end
    result = general_array(unique_type_texts)
    result
  end

  def general_array_with_seasonality
    tyre_season = url_shiny_hash_params
    result = []
    case tyre_season[:tyre_season]
    when 1
      param_season = "%letnie%"
    when 2
      param_season = "%zimnie%"
    when 3
      param_season = "%vsesezonie%"
    else
      param_season = "%season%"
    end
    if param_season != 0
      unique_type_texts = SeoContentText.where("type_text LIKE ?",
                                               param_season)
                                        .pluck(:type_text)
                                        .uniq

      result = general_array(unique_type_texts)
    end
    result
  end

  def general_array(unique_type_texts)
    selected_records = []
    unique_type_texts.each do |type_text|
      record = SeoContentText.where(type_text: type_text)
      content_type = record.count > 1 ? record.sample[:content_type] : record.first.try(:[], :content_type)
      selected_records << content_type if content_type
    end

    unique_str_seo_text = SeoContentTextSentence.pluck(:str_seo_text).uniq
    common_items = selected_records & unique_str_seo_text
    common_items
  end

  def total_arr_to_table(number_of_repeats_for_text = 1, number_of_repeats = 1)
    # h = data_json_to_hash
    h = params[:type_proc].to_i == 1 ? data_json_to_hash : array_after_error_from_json
    #=============================================================
    # Сделана замена хеша с учетом последней записи в базе данных:
    # h = array_after_error_from_json # при новом запуске закоментить
    #=============================================================

    # number_of_repeats_for_text = 5 # Задаем количество повторов вариантов для всего текста
    # number_of_repeats = 5 # количество вариантов написания каждого абзаца
    select_number_table = 1 # номер таблицы с результатами

    if params[:type_proc] == 0
      ind = 0 # определение номера блока текста в json
    else
      # Получить первый ключ хэша
      first_key = h.keys.first
      if first_key.present?
        ind = first_key.split('_').last.to_i if first_key.include?('_')
      else
        ind = 0
      end

    end

    count_record = 0 # подсчет обработанных записей
    h.each do |key, value|
      ind += 1
      # array = h["Block_" + ind.to_s]["TextBody"]
      # array.unshift(h["Block_" + ind.to_s]["TextTitle"])

      block_key = "Block_" + ind.to_s
      block_data = h[block_key]

      # если блока с нужным индексом нет в хеше или это не хеш - пропускаем итерацию
      if block_data.nil? || !block_data.is_a?(Hash)
        puts "Can't find key #{block_key} in hash or it's not a hash."
        next
      end

      array = block_data["TextBody"]
      array.unshift(block_data["TextTitle"])

      data_table_hash = {
        number_of_repeats_for_text: number_of_repeats_for_text,
        number_of_repeats: number_of_repeats,
        content_type: h["Block_" + ind.to_s]["TextTitle"],
        type_text: h["Block_" + ind.to_s]["TextType"],
        type_tag: h["Block_" + ind.to_s]["TextTypeTag"]&.to_i,
        order_out: h["Block_" + ind.to_s]["order_out"]&.to_i,
        str_number: 0
      }

      # puts "Current hash: #{h}"

      count_record += add_record_to_table(array, data_table_hash, select_number_table)
    end

    result = "В таблицу базы данных SeoContentText добавлены записи. === Кол-во: #{count_record}  "

    puts result
    # render json: { result: result }

  end

  def select_record_to_table_sentence(value_content_type)
    arr = SeoContentText.where(content_type: value_content_type).order(str_number: :asc).to_a
    arr.each do |el|
      array = el[:str].split(/[.?!]/)
      array.map!(&:strip) # Удалить пробелы в начале и в конце каждого предложения
      array.each_with_index do |sentence, i|
        SeoContentTextSentence.create(str_seo_text: el[:content_type],
                                      str_number: el[:str_number],
                                      sentence: sentence,
                                      num_snt_in_str: i
        )
      end
    end

  end

  def total_arr_to_table_sentence(number_of_repeats_for_text = 1, number_of_repeats = 1)
    # вызов c параметром all_recods=1
    # обрабатывает все тексты, без параметра с последней записи в sentence и до последней записи в text
    # number_of_repeats_for_text = 5 # Задаем количество повторов вариантов для всего текста
    # number_of_repeats = 5 # количество вариантов написания каждого предложения
    #========================================================
    select_number_table = 2 # номер таблицы с результатами
    count_record = 0 # подсчет обработанных записей

    arr_to_table_sentence = array_after_error_from_seo_content_text

    # SeoContentText.all.each do |record|
    arr_to_table_sentence&.each do |record|
      array = record[:str].split(/[.?!]/)
      array.map!(&:strip) # Удалить пробелы в начале и в конце каждого предложения
      content_type = record[:content_type]

      data_table_hash = {
        number_of_repeats_for_text: number_of_repeats_for_text,
        number_of_repeats: number_of_repeats,
        str_seo_text: content_type,
        str_number: record[:str_number],
        id_text: record[:id],
        type_text: record[:type_text]
      }

      # puts " array ==== #{array}"
      select_record_to_table_sentence(content_type) unless SeoContentTextSentence.where(str_seo_text: content_type).exists?
      count_record += add_record_to_table(array, data_table_hash, select_number_table)
    end
    # Находим и подчищаем все записи, содержащие число 195, 65, 15 .
    clear_size_in_sentence

    result = "В таблицу базы данных SeoContentTextSentence добавлены записи. === Кол-во: #{count_record}  "

    puts result
    # render json: { result: result }

  end

  def add_record_to_table(array, data_table_hash, select_number_table)
    count_record = 0
    el = ''
    array.each_with_index do |element, i|
      data_table_hash[:number_of_repeats_for_text].times do
        el = element
        replace_reverse_size_to_template(el)

        if select_number_table == 1
          data_table_hash[:str_number] = i
          txt = seo_phrase(el, data_table_hash[:number_of_repeats], i, select_number_table)
        end
        if select_number_table == 2
          data_table_hash[:num_snt_in_str] = i
          txt = seo_phrase(el, data_table_hash[:number_of_repeats],
                           data_table_hash[:str_number].to_i * 10 + i, # чтобы отличить заголовки от простой первой строки абзаца, если 0, то заголовок
                           select_number_table)
        end

        arr_result = make_array_phrase(txt, i)

        arr_to_table(arr_result, data_table_hash, select_number_table)
        count_record += 1
      end
    end
    count_record
  end

  # # задает количество вариантов написания для каждого абзаца исходного текста
  # def seo_phrase(element_array, number_of_repeats, ind, str_snt)
  #   str_snt == 1 ? topics = seo_phrase_str(element_array, number_of_repeats, ind) : topics = seo_phrase_sentence(element_array, number_of_repeats, ind)
  #
  #   new_text = ContentWriter.new.write_seo_text(topics, 3500) #['choices'][0]['message']['content'].strip
  #
  #   if new_text
  #     begin
  #       new_text = new_text['choices'][0]['message']['content'].strip
  #     rescue => e
  #       puts "Произошла ошибка: #{e.message}"
  #     end
  #   end
  #
  #   new_text
  # end
  #
  # def seo_phrase_sentence(element_array, number_of_repeats, ind)
  #   # задание на рерайт по предложениям
  #   # ind - номер строки в текте, если 0 - то заголовок
  #   topics = ''
  #   topics += element_array.to_s
  #   if ind > 0
  #     topics += "\n Сделай #{number_of_repeats} вариантов этого предложения. "
  #     topics += "\n Каждый вариант должен состоять из одного предложения. "
  #     topics += "\n Постарайся сохранить количество ключевых слов, при этом тошнотность текста должна быть не больше 20%,"
  #     topics += "\n а водность текста должна быть не больше 60%"
  #     topics += "\n Если в предложении используются названия шинных брендов, то их из текста не убирать."
  #     topics += "\n "
  #     topics += "\n Избегай построения предложения как рекламный слоган или рекламный заголовок, "
  #     topics += "\n а также предложений в которых только один главный член предложения (подлежащее или сказуемое)"
  #     topics += "\n Пример - "
  #     topics += "\n Неправильно: ProKoleso: Доступные цены на шины - гарантия качества!"
  #     topics += "\n Правильно: 'ProKoleso предоставляет доступные цены на шины с гарантией качества.' "
  #     topics += "\n "
  #     topics += "\n Не использовать личные местоимения в единственном числе "
  #     topics += "\n Пример - "
  #     topics += "\n Неправильно: 'Я оформлю вам заказ на доставку.'"
  #     topics += "\n Правильно: 'Мы оформим вам заказ на доставку'"
  #     topics += "\n "
  #     topics += "\n Старайтесь избегать употребления местоимений, таких как 'их', 'них', 'его', 'ее' и так далее "
  #     topics += "\n Пример - "
  #     topics += "\n Неправильно: 'Yokohama - компания, которая славится технологиями. Их продукция пользуется популярностью.'"
  #     topics += "\n Правильно: 'Yokohama славится технологиями. Продукция компании пользуется популярностью.' "
  #     topics += "\n "
  #
  #   else
  #     topics += "\n Сделай из этого текста #{number_of_repeats} вариантов эффектиного заголовка для статьи. "
  #     topics += "\n Заголовок должен состоять из одного предложения. "
  #   end
  #
  #   topics
  # end
  #
  # def seo_phrase_str(element_array, number_of_repeats, ind)
  #   # ind - номер строки в текте, если 0 - то заголовок
  #   topics = ''
  #   topics += element_array.to_s
  #   if ind > 0
  #     topics += "\n На тему, заданную в образце, Сделай #{number_of_repeats} вариантов текстов. "
  #     topics += "\n Количество  предложений в каждом варианте нужно сделать таким же, как в образце. "
  #     topics += "\n Количество печатных символов в ответе может быть больше, чем количество знаков в образце."
  #     topics += "\n Постарайся сохранить количество ключевых слов, при этом тошнотность текста должна быть не больше 20%,"
  #     topics += "\n а водность текста должна быть не больше 60%"
  #     topics += "\n Каждый вариант ответа должен состоять из одного абзаца (не использовать символ переноса каретки)"
  #     topics += "\n Предложения в абзаце должны быть самостоятельными по смыслу, т.е. не ссылаться на предыдущие предлжожения"
  #     topics += "\n Пример 1. "
  #     topics += "\n Неправильно: 'Шины различаются по типу. Каждый из этих типов шин имеет особенности'. "
  #     topics += "\n Правильно: 'Шины различаются по типу. Каждый тип шин имеет особенности'. "
  #     topics += "\n Пример 2. "
  #     topics += "\n Неправильно: 'Когда выбираете резину, не доверяйте низким ценам. Подобные предложения могут быть обманом'. "
  #     topics += "\n Правильно: 'Когда выбираете резину, не доверяйте низким ценам, подобные предложения могут быть обманом'. "
  #     topics += "\n Пример 3. "
  #     topics += "\n Неправильно: 'ProKoleso - надежный партнер для всех, кто ценит качество. Поэтому мы предлагаем лучшее'. "
  #     topics += "\n Правильно: 'ProKoleso - надежный партнер для всех, кто ценит качество. Мы предлагаем лучшее'. "
  #     topics += "\n Пример 4. "
  #     topics += "\n Неправильно: 'Не попадайтесь на предложение шин по недорогой цене. Чаще всего такие предложения обманчивы'. "
  #     topics += "\n Правильно: 'Не попадайтесь на предложение шин по недорогой цене. Дешевые предложения обманчивы'. "
  #     topics += "\n Пример 5. "
  #     topics += "\n Неправильно: 'Приобретение новых шин - залог безопасности. Поэтому выбирать нужно проверенных поставщиков'. "
  #     topics += "\n Правильно: 'Приобретение новых шин - залог безопасности. При покупке шин выбирать нужно проверенных поставщиков'. "
  #     topics += "\n Старайтесь избегать употребления местоимений, таких как 'их', 'них', 'его', 'ее' и так далее "
  #     topics += "\n Пример 6."
  #     topics += "\n Неправильно: 'Yokohama - компания, которая славится технологиями. Их продукция пользуется популярностью.'"
  #     topics += "\n Правильно: 'Yokohama славится технологиями. Продукция компании пользуется популярностью.' "
  #     topics += "\n "
  #     # topics += "\n  "
  #   else
  #     topics += "\n Сделай из этого текста #{number_of_repeats} вариантов эффектиного заголовка для статьи. "
  #     topics += "\n Заголовок должен состоять из одного предложения. "
  #   end
  #
  #   topics
  # end
  #
  # def make_array_phrase(var_phrase, i)
  #   txt = var_phrase.gsub("\n\n", "\n")
  #   txt = txt.gsub(/\*|\#/, "")
  #   txt = txt.gsub(/^("|)((\d+|)(|\s+))(В|в)ариант((|\s+)(|\d+(\s+|))(\.|\:|\-))/, "")
  #   txt = txt.split("\n")
  #   txt
  # end
  #
  # def arr_to_table(arr, data_table_hash, select_number_table)
  #   previous_el = ''
  #   i = 0
  #   arr.each do |el|
  #     str = el.sub(/^\d+(\.|\))\s/, '')
  #     str = str.gsub(/^('|")|('|")$/, '')
  #     replace_size_to_template(str)
  #
  #     # проверка на корректность ответов AI, если все ок, то записываем в таблицы
  #
  #     case select_number_table
  #     when 1
  #       SeoContentText.create(str: str,
  #                             order_out: data_table_hash[:order_out],
  #                             type_tag: data_table_hash[:type_tag],
  #                             type_text: data_table_hash[:type_text],
  #                             content_type: data_table_hash[:content_type],
  #                             str_number: data_table_hash[:str_number]
  #       ) if el.present? && el.length > 20
  #     when 2
  #       SeoContentTextSentence.create(str_seo_text: data_table_hash[:str_seo_text],
  #                                     str_number: data_table_hash[:str_number],
  #                                     sentence: str,
  #                                     num_snt_in_str: data_table_hash[:num_snt_in_str],
  #                                     id_text: data_table_hash[:id_text],
  #                                     type_text: data_table_hash[:type_text]
  #
  #       ) if el.present? && el.length > 20
  #     end
  #
  #   end
  # end
  #
  # def replace_size_tyre(array_of_string, url_params)
  #   arr = []
  #   size_count = array_of_string.count { |string| string.include?("[size]") }
  #   size_count.times do |i|
  #     arr << arr_size_name_min(url_params[:tyre_w], url_params[:tyre_h], url_params[:tyre_r], i)
  #   end
  #   arr
  # end
  #
  # def replace_params_w_h_r_tyre(str, url_params)
  #   str = str.gsub('[r-]', url_params[:tyre_r])
  #   str = str.gsub('[h-]', url_params[:tyre_h])
  #   str = str.gsub('[w-]', url_params[:tyre_w])
  #   str
  # end

  def generate_title_h2
    title_h2 = ""

    url_params = url_shiny_hash_params
    file_path = Rails.root.join('lib', 'template_texts', 'title_h2.json')
    file_data = File.read(file_path)
    hash_title = JSON.parse(file_data)

    case url_params[:tyre_season]
    when 1
      title_h2 = hash_title["letnie"].shuffle.first
    when 2
      title_h2 = hash_title["zimnie"].shuffle.first
    when 3
      title_h2 = hash_title["vsesezonie"].shuffle.first
    else
      title_h2 = hash_title["total"].shuffle.first
    end

    title_h2 = make_replace_for_title(title_h2, url_params) if title_h2.present?
    result = "<h2> #{title_h2} </h2>\n"
    result
  end

  def make_replace_for_title(str, url_params)
    replace_size_to_template(str)
    str = str.gsub('[size]', replace_name_size(url_params))
    brand = url_params[:tyre_brand]
    rpl = random_name_brand(brand)
    str = size_only_brand_in_url? ? str.gsub('Michelin ', rpl) : str.gsub('Michelin ', '')
    str
  end

  def random_name_brand(brand)
    rpl = ''
    if brand.present?
      records = Brand.where(url: brand)
      arr = []
      first_char_word1 = brand[0].downcase
      records.each do |record|
        first_char_word2 = Translit.convert(record[:name][0], :english).downcase
        if first_char_word1 == first_char_word2 || first_char_word1 == record[:name][0]
          arr << record[:name].capitalize
          arr << "#{record[:name].capitalize} (#{brand.capitalize})" if first_char_word1 == first_char_word2
        end
      end
      rpl = arr.shuffle.first
    end
    rpl
  end

  def generator_text(content_type)
    # количество абзацев в выбранном типе текста
    max_str_number = SeoContentText.where(content_type: content_type).maximum(:str_number)
    SeoContentText.where(content_type: content_type).first.try(:[], :type_tag) == 1 ? tag_li = "li" : tag_li = "p"
    text = ""
    array = []
    url_params = url_shiny_hash_params

    unless max_str_number.nil?
      processed_record = ''
      max_str_number += 1
      (max_str_number).times do |i|

        max_str_number_sentence = SeoContentTextSentence.where(str_seo_text: content_type, str_number: i).maximum(:num_snt_in_str)
        processed_record = ''
        (max_str_number_sentence + 1).times do |j|
          random_sentence = SeoContentTextSentence.where(str_seo_text: content_type, str_number: i, num_snt_in_str: j)
                                                  .order("RANDOM()")
                                                  .first
          if random_sentence && random_sentence[:sentence]
            str = random_sentence[:sentence]
            str += "." if ends_with_punctuation?(str)
            processed_record += " #{str}"
          end
          processed_record
        end

        processed_record = replace_params_w_h_r_tyre(processed_record, url_params)
        array << processed_record
      end

      first_element = array.first
      first_element = first_element.gsub('[size]', replace_name_size(url_params))

      rest_of_array = array.drop(1) #.shuffle
      # задается случайный порядок предложений в абзаце

      rest_of_array.map! do |string|
        sentences = string.split(/(?<=\?|\.|!)\s/)
        shuffled_sentences = sentences #.shuffle.shuffle
        string_new = shuffled_sentences.join(" ")
        string_new = string_new.gsub('[size]', replace_name_size(url_params))
        string_new = "<#{tag_li}>" + string_new + "</#{tag_li}>"
        string_new
      end

      first_str = '<h3>' + first_element + '</h3>' + "\n"
      arr_body_text = change_text_order(rest_of_array).join("\n")

      if tag_li == "li"
        rand(1..2) % 2 == 0 ? tag_ul_ol = "ul" : tag_ul_ol = "ol"
        arr_body_text = "<#{tag_ul_ol}>\n" + arr_body_text + "\n</#{tag_ul_ol}>\n"
      end

      text += first_str + arr_body_text
    end

    text

  end

  def ends_with_punctuation?(str)
    str.rstrip
    !str.match?(/[.!?]\z/)
  end

  def change_text_order(array)
    if array.last =~ /\?\s*$/
      last_element = array.pop
      array.unshift(last_element)
    end
    array
  end

end