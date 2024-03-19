# app/controllers/api/v1/seo_texts_controller.rb
require 'benchmark'

class Api::V1::SeoTextsController < ApplicationController
  include StringProcessing
  include StringErrorsProcessing
  include TextOptimization

  def json_write_for_read
    # Из текстового файла создает файл json с массивом строк, для дальнейшей подготовки к обработке
    # для запуска: внести текст, для обработки в файл lib/template_texts/data.txt
    # пример файла:
    # TextType: strTextType
    # TextTitle: Покупка АВТОШИНЫ 205/60R16 ответственный выбор.
    #   TextBody: Купить в Украине
    #
    # TextType: strTextType1
    # TextTitle: АВТОШИНЫ 205/60R16.
    #   TextBody:  Украине нужные шины Украине нужные шины Украине
    # нужные шины Украине нужные шины Украине нужные шины

    txt_file_to_json
    render json: { result: "Создан файл lib/template_texts/data.json" }
    # после обработки готовый файл нужно перенести в папку finished_texts
  end
  def raw_text
    # пример:
    # curl http://localhost:3000/api/v1/seo_text?url=https%3A%2F%2Fprokoleso.ua%2Fshiny%2Fletnie%2Fkumho%2Fw-175%2Fh-70%2Fr-13%2F
    result = ''
    alphanumeric_chars_count = 0
    general_array_without_season = general_array_without_seasonality.shuffle
    puts "common_items - #{general_array_without_season.inspect}"
    while alphanumeric_chars_count < 3000 && general_array_without_season.any?
      content_type = general_array_without_season.first
      general_array_without_season = general_array_without_season.drop(1)

      result += generator_text(content_type) + "\n"
      alphanumeric_chars_count = result.scan(/[\p{L}\p{N}]/).length
    end

    content_type = general_array_with_seasonality.first
    result += generator_text(content_type) + "\n"

    result += arr_url_result_str if print_errors_text?
    # alphanumeric_chars_count = result.scan(/[\p{L}\p{N}]/).length
    # puts alphanumeric_chars_count
    result
  end

  def seo_text

    result = replace_trash(raw_text)
    puts result
    alphanumeric_chars_count = result&.scan(/[\p{L}\p{N}]/)&.length
    puts "количество значимых символов - #{alphanumeric_chars_count}"
    puts adjust_keyword_stuffing(result)


    render json: { result: result }

  end

  def general_array_without_seasonality
    unique_type_texts = SeoContentText.where("type_text NOT LIKE ? AND type_text NOT LIKE ? AND type_text NOT LIKE ?",
                                             "%season%", "%letnie%", "%zimnie%")
                                      .pluck(:type_text)
                                      .uniq

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
      param_season = 0
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

  def total_arr_to_table
    h = data_json_to_hash
    number_of_repeats_for_text = 1 # Задаем количество повторов вариантов для всего текста
    number_of_repeats = 1 # количество вариантов написания каждого абзаца
    select_number_table = 1 # номер таблицы с результатами
    ind = 0 # определение номера блока текста в json
    count_record = 0 # подсчет обработанных записей
    h.each do |key, value|
      ind += 1
      array = h["Block_" + ind.to_s]["TextBody"]
      array.unshift(h["Block_" + ind.to_s]["TextTitle"])
      data_table_hash = {
        number_of_repeats_for_text: number_of_repeats_for_text,
        number_of_repeats: number_of_repeats,
        content_type: h["Block_" + ind.to_s]["TextTitle"],
        type_text: h["Block_" + ind.to_s]["TextType"],
        order_out: h["Block_" + ind.to_s]["order_out"]&.to_i,
        str_number: 0
      }
      puts " array ==== #{array}"

      count_record += add_record_to_table(array, data_table_hash, select_number_table)
    end

    result = "В таблицу базы данных SeoContentText добавлены записи. === Кол-во: #{count_record}  "

    puts result
    render json: { result: result }

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

  def total_arr_to_table_sentence
    number_of_repeats_for_text = 1 # Задаем количество повторов вариантов для всего текста
    number_of_repeats = 1 # количество вариантов написания каждого предложения
    #========================================================
    select_number_table = 2 # номер таблицы с результатами
    count_record = 0 # подсчет обработанных записей

    SeoContentText.all.each do |record|
      array = record[:str].split(/[.?!]/)
      array.map!(&:strip) # Удалить пробелы в начале и в конце каждого предложения
      content_type = record[:content_type]

      data_table_hash = {
        number_of_repeats_for_text: number_of_repeats_for_text,
        number_of_repeats: number_of_repeats,
        str_seo_text: content_type,
        str_number: record[:str_number]
      }

      puts " array ==== #{array}"
      select_record_to_table_sentence(content_type) unless SeoContentTextSentence.where(str_seo_text: content_type).exists?
      count_record += add_record_to_table(array, data_table_hash, select_number_table)
    end

    result = "В таблицу базы данных SeoContentText добавлены записи. === Кол-во: #{count_record}  "

    puts result
    render json: { result: result }

  end

  def add_record_to_table(array, data_table_hash, select_number_table)
    count_record = 0
    el = ''
    array.each_with_index do |element, i|
      data_table_hash[:number_of_repeats_for_text].times do
        el = element
        replace_reverse_size_to_template(el)
        txt = seo_phrase(el, data_table_hash[:number_of_repeats], i, select_number_table)
        # txt = "test test test test test test test test test test test test test test "
        arr_result = make_array_phrase(txt, i)
        data_table_hash[:str_number] = i if select_number_table == 1
        data_table_hash[:num_snt_in_str] = i if select_number_table == 2
        arr_to_table(arr_result, data_table_hash, select_number_table)
        count_record += 1
      end
    end
    count_record
  end

  # задает количество вариантов написания для каждого абзаца исходного текста
  def seo_phrase(element_array, number_of_repeats, ind, str_snt)
    str_snt == 1 ? topics = seo_phrase_str(element_array, number_of_repeats, ind) : topics = seo_phrase_sentence(element_array, number_of_repeats, ind)

    new_text = ContentWriter.new.write_seo_text(topics, 3500) #['choices'][0]['message']['content'].strip

    if new_text
      begin
        new_text = new_text['choices'][0]['message']['content'].strip
      rescue => e
        puts "Произошла ошибка: #{e.message}"
      end
    end

    new_text
  end

  def seo_phrase_sentence(element_array, number_of_repeats, ind)
    # задание на рерайт по предложениям
    topics = ''
    topics += element_array.to_s
    if ind > 0
      topics += "\n Сделай #{number_of_repeats} вариантов этого предложения."
      topics += "\n Если в предложении используются названия шинных брендов, то их из текста не убирать."
      topics += "\n "
      topics += "\n Избегай построения предложения как рекламный слоган или рекламный заголовок, "
      topics += "\n а также предложений в которых только один главный член предложения (подлежащее или сказуемое)"
      topics += "\n Пример - "
      topics += "\n Неправильно: ProKoleso: Доступные цены на шины Bridgestone - гарантия качества!"
      topics += "\n Правильно: 'ProKoleso предоставляет доступные цены на шины Bridgestone с гарантией качества.' "
      topics += "\n "
      topics += "\n Не использовать личные местоимения в единственном числе "
      topics += "\n Пример - "
      topics += "\n Неправильно: 'Я оформлю вам заказ на доставку.'"
      topics += "\n Правильно: 'Мы оформим вам заказ на доставку'"
      topics += "\n "
      topics += "\n Старайтесь избегать употребления местоимений, таких как 'их', 'них', 'его', 'ее' и так далее "
      topics += "\n Пример - "
      topics += "\n Неправильно: 'Yokohama - компания, которая славится технологиями. Их продукция пользуется популярностью.'"
      topics += "\n Правильно: 'Yokohama - компания, которая славится технологиями. Продукция этого бренда пользуется популярностью.' "
      topics += "\n "

    else
      topics += "\n Сделай из этого текста #{number_of_repeats} вариантов эффектиного заголовка для статьи. "
      topics += "\n Заголовок должен состоять из одного предложения. "
    end

    topics
  end

  def seo_phrase_str(element_array, number_of_repeats, ind)
    topics = ''
    topics += element_array.to_s
    if ind > 0
      topics += "\n На тему, заданную в образце, Сделай #{number_of_repeats} вариантов текстов."
      topics += "\n Количество печатных символов в ответе может быть больше, чем количество знаков в образце."
      topics += "\n Постарайся сохранить количество ключевых слов, при этом тошнотность текста должна быть не больше 20%"
      topics += "\n Каждый вариант ответа должен состоять из одного абзаца (не использовать символ переноса каретки)"
      topics += "\n Предложения в абзаце должны быть самостоятельными по смыслу, т.е. не ссылаться на предыдущие предлжожения"
      topics += "\n Пример 1. "
      topics += "\n Неправильно: 'Шины различаются по типу назначения. Каждый из этих типов шин имеет особенности'. "
      topics += "\n Правильно: 'Шины различаются по типу назначения. Каждый тип шин имеет особенности'. "
      topics += "\n Пример 2. "
      topics += "\n Неправильно: 'Когда выбираете резину, не доверяйте подозрительно низким ценам. Подобные предложения могут быть для товаров без гарантий'. "
      topics += "\n Правильно: 'Когда выбираете резину, не доверяйте подозрительно низким ценам, подобные предложения могут быть для товаров без гарантий'. "
      topics += "\n Пример 3. "
      topics += "\n Неправильно: 'Компания ProKoleso - это надежный партнер для всех, кто ценит качество и надежность. Поэтому мы предлагаем только лучшее'. "
      topics += "\n Правильно: 'Компания ProKoleso - это надежный партнер для всех, кто ценит качество и надежность. Мы предлагаем только лучшее'. "
      topics += "\n Пример 4. "
      topics += "\n Неправильно: 'Не попадайтесь на уловки магазинов, предлагающих шины по недорогой цене. Чаще всего такие предложения скрывают низкое качество товара'. "
      topics += "\n Правильно: 'Не попадайтесь на уловки магазинов, предлагающих шины по недорогой цене. Дешевые предложения скрывают низкое качество товара'. "
      topics += "\n Пример 5. "
      topics += "\n Неправильно: 'Приобретение новых шин - залог вашей безопасности на дороге. Поэтому выбирать лучше всего проверенных поставщиков'. "
      topics += "\n Правильно: 'Приобретение новых шин - залог вашей безопасности на дороге. При покупке шин выбирать лучше всего проверенных поставщиков'. "
      topics += "\n Старайтесь избегать употребления местоимений, таких как 'их', 'них', 'его', 'ее' и так далее "
      topics += "\n Пример 6."
      topics += "\n Неправильно: 'Yokohama - компания, которая славится технологиями. Их продукция пользуется популярностью.'"
      topics += "\n Правильно: 'Yokohama - компания, которая славится технологиями. Продукция этого бренда пользуется популярностью.' "
      topics += "\n "
      # topics += "\n  "
    else
      topics += "\n Сделай из этого текста #{number_of_repeats} вариантов эффектиного заголовка для статьи. "
      topics += "\n Заголовок должен состоять из одного предложения. "
    end

    topics
  end

  def make_array_phrase(var_phrase, i)
    txt = var_phrase.gsub("\n\n", "\n")
    txt = txt.gsub(/\*|\#/, "")
    txt = txt.gsub(/^("|)((\d+|)(|\s+))(В|в)ариант((|\s+)(|\d+(\s+|))(\.|\:|\-))/, "")
    txt = txt.split("\n")
    txt
  end

  def arr_to_table(arr, data_table_hash, select_number_table)
    previous_el = ''
    i = 0
    arr.each do |el|
      str = el.sub(/^\d+(\.|\))\s/, '')
      str = str.gsub(/^('|")|('|")$/, '')
      replace_size_to_template(str)
      case select_number_table
      when 1
        SeoContentText.create(str: str,
                              order_out: data_table_hash[:order_out],
                              type_text: data_table_hash[:type_text],
                              content_type: data_table_hash[:content_type],
                              str_number: data_table_hash[:str_number]
        ) if el.present? && el.length > 20
      when 2
        SeoContentTextSentence.create(str_seo_text: data_table_hash[:str_seo_text],
                                      str_number: data_table_hash[:str_number],
                                      sentence: str,
                                      num_snt_in_str: data_table_hash[:num_snt_in_str]
        ) if el.present? && el.length > 20
      end

    end
  end

  def replace_size_tyre(array_of_string, url_params)
    arr = []
    size_count = array_of_string.count { |string| string.include?("[size]") }
    size_count.times do |i|
      arr << arr_size_name_min(url_params[:tyre_w], url_params[:tyre_h], url_params[:tyre_r], i)
    end
    arr
  end

  def replace_params_w_h_r_tyre(str, url_params)
    str = str.gsub('[r-]', url_params[:tyre_r])
    str = str.gsub('[h-]', url_params[:tyre_h])
    str = str.gsub('[w-]', url_params[:tyre_w])
    str
  end

  def generator_text(content_type)
    # количество абзацев в выбранном типе текста
    max_str_number = SeoContentText.where(content_type: content_type).maximum(:str_number)
    SeoContentText.where(content_type: content_type).first.try(:[], :type_text) =~ /_1/ ? tag_li = "li" : tag_li = "p"
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

          str = random_sentence[:sentence]
          str += "." if ends_with_punctuation?(str)
          processed_record += " #{str}"
        end

        processed_record = replace_params_w_h_r_tyre(processed_record, url_params)
        array << processed_record
      end

      first_element = array.first
      first_element = first_element.gsub('[size]', replace_name_size(url_params))

      rest_of_array = array.drop(1).shuffle
      # задается случайный порядок предложений в абзаце

      rest_of_array.map! do |string|
        sentences = string.split(/(?<=\?|\.|!)\s/)
        shuffled_sentences = sentences.shuffle
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
    text = text.gsub(/\.\s*\./, ".")
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