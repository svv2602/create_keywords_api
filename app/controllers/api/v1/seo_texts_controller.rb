# app/controllers/api/v1/seo_texts_controller.rb
require 'benchmark'

class Api::V1::SeoTextsController < ApplicationController
  include StringProcessing
  include StringErrorsProcessing
  include TextOptimization
  include StringProcessingServices
  include ServiceTable
  include ServiceQuestion

  def mytest

    # all_questions_for_page
    result = count_text_type("data_disk")
    puts "Все сделано! ===== #{result.inspect} " # #{result.inspect}
    render json: { result: result }
  end

  def count_text_type(file_name_txt)
    # подсчет количества тем в текстовом фале
    # путь к файлу в рельс
    file_path = Rails.root.join('lib', 'template_texts', "#{file_name_txt}.txt")

    # Инициализируем хэш для подсчета строк
    lines_count = Hash.new(0)

    # открытие файла 'data_track.txt' для чтения
    File.open(file_path, 'r') do |file|
      # Читаем файл и разделяем его на строки
      lines = file.readlines

      # Выбираем строки, содержащие 'TextType'
      text_type_lines = lines.select { |line| line.include?('TextType:') }

      # Увеличиваем подсчет в Хэше для каждой строки
      text_type_lines.each { |line| lines_count[line] += 1 }
    end
    result = ""
    # Вернуть хэш с подсчетом строк
    lines_count.each do |line, count|
      result += "#{line.strip.gsub("TextType: ", "")} : #{count};  "
    end
    result

  end

  def total_generate_seo_text
    # !!!!!!!!!! Внимание - первый запуск нового файла ОБЯЗАТЕЛЬНО с параметром type_proc=1
    # Первоначальное заполнение таблиц с текстами
    # Перенос первоначальных текстов в json
    order_out = 1
    filename = case order_out
               when 0
                 "data" # для легковых шин
               when 1
                 "data_disk" # для дисков
               when 2
                 "data_track" # для грузовых шин
               end

    # добавить тексты в json
    # txt_file_to_json(filename)

    file_path = Rails.root.join('lib', 'template_texts', "#{filename}.json")
    # if duplicated_in_data_json?(file_path) #- проверка на дубликаты
    # ============== проверено ==========
    # total_arr_to_table(7, 5, order_out, filename)
    # ============== проверено ==========
    update_seo_content_text_sentence_id_text
    total_arr_to_table_sentence(5, 3, order_out) # - для дисков !!!! сделать
    update_seo_content_text_sentence_id_text
    # # сделать копию базы и запустить( для легковых )
    # table = 'seo_content_text_sentences'
    # remove_empty_sentences(table) # удаление пустых записей
    # replace_errors_size(table) # удаление записей с ошибками

    # end

    # ===========================================================
    # # ВНИМАНИЕ!!!
    # #===========================================================
    # # для полной обработки набирать с параметром params[:type_proc] = 1
    # # пример: curl http://localhost:3000/api/v1/total_generate_seo_text?type_proc=0
    # # В total_arr_to_table, иначе обработке файла data.json - будет неполной
    # #===========================================================

    # ===================================================
    # repeat_sentences_generation # дополнение до 25 - вставить если нужно
    # ===================================================
    # Сделать переводы в xlsx  app/controllers/exports_controller.rb методы для экспорта данных из базы данных
    # proc_import_text_ua
    # delete_records_with_instructions  # удаление записей с ошибками
    # delete_records_for_id

    puts "Все сделано!"
    render json: { result: "Все сделано!" }

  end

  def json_write_for_read
    # Из текстового файла создает файл json с массивом строк, для дальнейшей подготовки к обработке
    # для запуска: внести текст, для обработки в файл lib/template_texts/data.txt
    filename = "data_track"
    txt_file_to_json(filename)
    # clear_size_temp # для обновления данных в таблице
    render json: { result: "Создан файл lib/template_texts/#{filename}.json" }
    # после обработки готовый файл нужно перенести в папку finished_texts
  end

  def raw_text
    result = ''
    min_chars = 0
    order_out = url_type_by_parameters
    arr_size = order_out == 1 ? arr_size_diski_to_error : arr_size_to_error
    alphanumeric_chars_count = 0
    general_array_without_season = general_array_without_seasonality.shuffle
    # puts "common_items - #{general_array_without_season.inspect}"

    # alphanumeric_chars_count_for_url_shiny - метод для определения базового количества символов в зависимости от урла
    min_chars = alphanumeric_chars_count_for_url_shiny if order_out == 0
    min_chars = alphanumeric_chars_count_for_url_diski if order_out == 1
    min_chars = alphanumeric_chars_count_for_url_gruzovye_shiny if order_out == 2

    while alphanumeric_chars_count < min_chars && general_array_without_season.any?
      content_type = general_array_without_season.first
      general_array_without_season = general_array_without_season.drop(1)

      result += generator_text(content_type, order_out) + "\n"
      arr = arr_size.shift(5)
      result += min_errors_text(arr) if size_present_in_url?

      alphanumeric_chars_count = result.scan(/[\p{L}\p{N}]/).length
    end

    # добавление текста по сезону

    # ================= content_type = general_array_with_seasonality.first =====================
    # Добавить условие в зависимости от урла по сезонности (нужен ли текст вообще?)
    # +++++++++++++++++++++++++++++++++++++++++++++

    # ============ сезонность для легковых шин ============================

    content_type = case url_type_by_parameters
                   when 0
                     general_array_with_seasonality.first
                   when 1
                     general_array_with_type_disk.first
                   when 2
                     general_array_with_axis.first
                   end

    # if url_type_by_parameters == 0
    #   content_type = general_array_with_seasonality.first
    #   result += generator_text(content_type, order_out) + "\n"
    # end
    # if url_type_by_parameters == 2
    #   content_type = general_array_with_axis.first
    #   result += generator_text(content_type, order_out) + "\n"
    # end
    result += generator_text(content_type, order_out) + "\n"

    # удаляем похожие предложения
    result = similar_sentences_delete(result)

    # Добавление текста об ошибках , если в url есть размер
    if size_present_in_url?
      result += size_present_in_popular? ? arr_url_result_str : min_errors_text(arr_size)
    end

    # убираем лишние знаки пунктуации
    # result = standardization_of_punctuation(result)

    result
  end

  def min_errors_text(arr_size)
    result = ''
    array_with_text = url_type_by_parameters == 1 ? TEMPLATE_TEXT_DISKI_ERROR : TEMPLATE_TEXT_ERROR
    array_with_text_ua = url_type_by_parameters == 1 ? TEMPLATE_TEXT_DISKI_ERROR_UA : TEMPLATE_TEXT_ERROR_UA

    if !size_present_in_popular? && !arr_size.empty?
      text_err = "<br>\n"
      text_err += "<p class='keywords-size'>"
      text_err += url_type_ua? ? array_with_text_ua.shuffle.first : array_with_text.shuffle.first
      text_err += " " + arr_size.shift(5).join(', ')
      text_err += "</p><br>\n"
      result += text_err
    end
    result
  end

  def raw_text_final
    text = raw_text
    result = replace_trash(text)

    alphanumeric_chars_count = result&.scan(/[\p{L}\p{N}]/)&.length
    puts "количество значимых символов - #{alphanumeric_chars_count}"
    puts "Было:" + "=" * 80
    puts adjust_keyword_stuffing(result)

    # оптимизация текста по ключевым словам
    if url_type_ua?
      # оптимизация для украинского текста
    else
      # оптимизация для русского текста, может потом переделать
      if url_type_by_parameters == 0
        # для легковых шин
        result = replace_text_by_hash(result)
        result = replace_text_by_hash_minus(result)
      end
    end

    puts "Стало:" + "=>" * 40

    # Добавляем ссылки:
    insert_brand_url(result) if type_for_url_shiny != 10
    result = insert_season_url_new(result)

    result = generate_title_h2 + result + "<br>"

    # убираем лишние знаки пунктуации
    result = standardization_of_punctuation(result)

    puts adjust_keyword_stuffing(result)
    # puts result
    result
  end

  def seo_text
    # пример:
    # легковые:
    # curl http://localhost:3000/api/v1/seo_text?url=https%3A%2F%2Fprokoleso.ua%2Fshiny%2Fletnie%2Fkumho%2Fw-175%2Fh-70%2Fr-13%2F
    # грузовые
    # https://prokoleso.ua/ua/gruzovye-shiny/w-385/h-65/r-22.5/axis-pritsepnaya/aeolus/
    # curl http://localhost:3000/api/v1/seo_text?url=https%3A%2F%2Fprokoleso.ua%2Fgruzovye-shiny%2Fw-385%2Fh-65%2Fr-22.5%2Faxis-pritsepnaya%2Faeolus%2F

    result = raw_text_final || ""
    result_questions = all_questions_for_page || ""

    puts result + "\n" + result_questions
    render json: { result: result,
                   result_questions: result_questions
    }

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
      if (10..14).include?(type_for_url_shiny) || (110..114).include?(type_for_url_shiny)
        patterns = ['%ассортимент_diski%', '%легкосплав_diski%', '%железные_diski%', '%общий_diski%']
      else
        patterns = ['%легкосплав_diski%', '%железные_diski%', '%общий_diski%']
      end
      query += " AND " + patterns.map { "type_text NOT LIKE ?" }.join(" AND ")

    when 2 # грузовые шины
      query = "order_out = 2 "
      if (10..14).include?(type_for_url_shiny) || (110..114).include?(type_for_url_shiny)
        patterns = ['%универсальные%', '%рулевые%', '%прицеп%', '%ведущие%', '%ассортимент%']
      else
        patterns = ['%универсальные%', '%рулевые%', '%прицеп%', '%ведущие%']
      end
      query += " AND " + patterns.map { "type_text NOT LIKE ?" }.join(" AND ")
    end

    unique_type_texts = SeoContentText.where(query, *patterns).pluck(:type_text).uniq
    # puts "unique_type_texts ================ #{unique_type_texts.inspect}"
    result = general_array(unique_type_texts, url_type_by_parameters)
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

      result = general_array(unique_type_texts, url_type_by_parameters)
    end
    result
  end

  def general_array_with_type_disk
    disk_url = url_shiny_hash_params
    result = []
    case disk_url[:disk_type]
    when 1
      param_type = "%легкосплав_diski%"
    when 2
      param_type = "%железные_diski%"
    else
      param_type = "%общий_diski%"
    end
    if param_type != 0
      unique_type_texts = SeoContentText.where("type_text LIKE ?",
                                               param_type)
                                        .pluck(:type_text)
                                        .uniq

      result = general_array(unique_type_texts, url_type_by_parameters)
    end
    result
  end

  def general_array_with_axis
    tyre_axis = url_shiny_hash_params
    result = []
    case tyre_axis[:tyre_season]
    when 1
      param_axis = "%прицеп%"
    when 2
      param_axis = "%рулевые%"
    when 3
      param_axis = "%ведущие%"
    else
      param_axis = "%универсальные%"
    end
    if param_axis != 0
      unique_type_texts = SeoContentText.where("type_text LIKE ?",
                                               param_axis)
                                        .pluck(:type_text)
                                        .uniq

      result = general_array(unique_type_texts, url_type_by_parameters)
    end
    result
  end

  def general_array(unique_type_texts, url_type_by_parameters)
    selected_records = []
    unique_type_texts.each do |type_text|
      record = SeoContentText.where(type_text: type_text, order_out: url_type_by_parameters)
      content_type = record.count > 1 ? record.sample[:content_type] : record.first.try(:[], :content_type)
      selected_records << content_type if content_type
    end

    unique_str_seo_text = SeoContentTextSentence.pluck(:str_seo_text).uniq
    common_items = selected_records & unique_str_seo_text
    common_items
  end

  def total_arr_to_table(number_of_repeats_for_text = 1, number_of_repeats = 1, order_out = 0, filename)
    # h = data_json_to_hash

    # Внимание - первый запуск нового файла ОБЯЗАТЕЛЬНО с параметром type_proc=1
    h = params[:type_proc].to_i == 1 ? data_json_to_hash(filename) : array_after_error_from_json(filename)
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

  def total_arr_to_table_sentence(number_of_repeats_for_text = 1, number_of_repeats = 1, order_out = 0)
    # вызов c параметром all_recods=1
    # обрабатывает все тексты, без параметра с последней записи в sentence и до последней записи в text
    # number_of_repeats_for_text = 5 # Задаем количество повторов вариантов для всего текста
    # number_of_repeats = 5 # количество вариантов написания каждого предложения
    #========================================================
    select_number_table = 2 # номер таблицы с результатами
    count_record = 0 # подсчет обработанных записей

    arr_to_table_sentence = array_after_error_from_seo_content_text(order_out)

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
    if url_type_by_parameters == 0
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

    end

    if url_type_by_parameters == 2
      title_h2 = hash_title["track"].shuffle.first
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

  def generator_text(content_type, order_out)
    # количество абзацев в выбранном типе текста
    max_str_number = SeoContentText.where(content_type: content_type, order_out: order_out).maximum(:str_number)
    SeoContentText.where(content_type: content_type, order_out: order_out).first.try(:[], :type_tag) == 1 ? tag_li = "li" : tag_li = "p"
    text = ""
    array = []
    url_params = url_shiny_hash_params

    unless max_str_number.nil?
      processed_record = ''
      max_str_number += 1
      (max_str_number).times do |i|

        max_str_number_sentence = SeoContentTextSentence.where(str_seo_text: content_type, str_number: i).maximum(:num_snt_in_str)
        processed_record = ''
        # puts "max_str_number = #{max_str_number}: max_str_number_sentence = #{max_str_number_sentence} "
        # puts "content_type = #{content_type}  : processed_record = #{processed_record} "
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