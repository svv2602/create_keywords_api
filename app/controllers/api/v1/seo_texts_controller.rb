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
    text = "<p> size [size] size  моС size летние. [size] летние моСк овский покрышки R18 Kumho, HANKOOK отличает прочная конструкция. И я,апаппа. летние моСковский покрышки R18 Kumho, HANKOOK"

    result = remove_small_sentences(text, min_count = 3)
    puts "Все сделано! =====  #{result.inspect}"
    render json: { result: result }
  end

  def total_generate_seo_text

    # Первоначальное заполнение таблиц с текстами
    # Перенос первоначальных текстов в json
    # bb?
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

      # total_arr_to_table_sentence(5, 5)

    end

    # заново =============
    # исправляется ошибка с формированием перввой строки абзацев
    replace_errors_title_sentence
    # заново =============

    # сделать копию базы и запустить
    table = 'seo_content_text_sentences'
    remove_empty_sentences(table) # удаление пустых записей
    result = replace_errors_size(table) # удаление записей с ошибками
    repeat_sentences_generation # дополнение до 25



    puts "Все сделано! удалено - #{result}"
    render json: { result: "Все сделано!" }

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
    min_chars = 0
    arr_size = arr_size_to_error
    alphanumeric_chars_count = 0
    general_array_without_season = general_array_without_seasonality.shuffle
    # puts "common_items - #{general_array_without_season.inspect}"

    # alphanumeric_chars_count_for_url_shiny - метод для определения базового количества символов в зависимости от урла
    min_chars = alphanumeric_chars_count_for_url_shiny if url_type_by_parameters == 0

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

    # ============ сезонность для легковых шин ============================
    if url_type_by_parameters == 0
      content_type = general_array_with_seasonality.first
      result += generator_text(content_type) + "\n"
    end

    # удаляем похожие предложения
    result = similar_sentences_delete(result)

    # Добавление текста об ошибках , если в url есть размер
    if size_present_in_url?
      if url_type_ua?
        result += min_errors_text(arr_size)
      else
        result += size_present_in_popular? ? arr_url_result_str : min_errors_text(arr_size)
      end

    end

    # убираем лишние знаки пунктуации
    # result = standardization_of_punctuation(result)

    result
  end

  def min_errors_text(arr_size)
    result = ''
    if !size_present_in_popular? && !arr_size.empty?
      text_err = "<br>\n"
      text_err += "<p class='keywords-size'>"
      url_type_ua?
      text_err += url_type_ua? ? TEMPLATE_TEXT_ERROR_UA.shuffle.first : TEMPLATE_TEXT_ERROR.shuffle.first
      text_err += " " + arr_size.shift(5).join(', ')
      text_err += "</p><br>\n"
      result += text_err
    end
    result
  end

  def seo_text
    # curl http://localhost:3000/api/v1/seo_text?url=https%3A%2F%2Fprokoleso.ua%2Fshiny%2Fletnie%2Fkumho%2Fw-175%2Fh-70%2Fr-13%2F
    text = raw_text
    result = replace_trash(text)

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

    # убираем лишние знаки пунктуации
    result = standardization_of_punctuation(result)

    puts adjust_keyword_stuffing(result)
    puts result
    render json: { result: result }

  end

  def general_array_without_seasonality
    # подбор текстов по урлу
    # переписать потом, если надо будет убрать еще типы статей для разных урлов,
    # сделать вначале отбор записей таблицы, а потом отбор по сезонам и .pluck
    patterns = []
    case url_type_by_parameters
    when 0 # легковые
      query = "order_out = 0 "
      if (10..14).include?(type_for_url_shiny) || (110..114).include?(type_for_url_shiny)
        # puts "Значение в диапазоне от 10 до 14"
        # убираем статьи с сезоном и ассортиметом для брендов
        patterns = ['%season%', '%letnie%', '%zimnie%', '%vsesezonie%', '%ассортимент%']
      else
        # puts "Значение вне диапазона от 10 до 14"
        # просто убираем статьи с сезоном
        patterns = ['%season%', '%letnie%', '%zimnie%', '%vsesezonie%']
      end
      query += " AND " + patterns.map { "type_text NOT LIKE ?" }.join(" AND ")

    when 1 # легковые диски
      query = "order_out = 1 "
    when 2 # грузовые шины
      query = "order_out = 2 "
    end

    unique_type_texts = SeoContentText.where(query, *patterns).pluck(:type_text).uniq
    puts "unique_type_texts ================ #{unique_type_texts.inspect}"
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
        type_text: record[:type_text],
        check_title: 0

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

  def generate_title_h2
    title_h2 = ""

    url_params = url_shiny_hash_params
    file_name = url_type_ua? ? 'title_h2_ua.json' : 'title_h2.json'
    file_path = Rails.root.join('lib', 'template_texts', file_name)
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
        puts "max_str_number = #{max_str_number}: max_str_number_sentence = #{max_str_number_sentence} "
        puts "content_type = #{content_type}  : processed_record = #{processed_record} "
        break if max_str_number_sentence.nil?

        (max_str_number_sentence + 1).times do |j|
          random_sentence = SeoContentTextSentence.where(str_seo_text: content_type, str_number: i, num_snt_in_str: j)
                                                  .order("RANDOM()")
                                                  .first
          if random_sentence && random_sentence[:sentence]
            # выбираем язык предложения
            str = url_type_ua? ? random_sentence[:sentence_ua] : random_sentence[:sentence]
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