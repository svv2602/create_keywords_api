# app/controllers/api/v1/seo_texts_controller.rb
require 'benchmark'

class Api::V1::SeoTextsController < ApplicationController
  include StringProcessing

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

  def seo_text
    # пример:
    # curl http://localhost:3000/api/v1/seo_text?url=https%3A%2F%2Fprokoleso.ua%2Fshiny%2Fletnie%2Fkumho%2Fw-175%2Fh-70%2Fr-13%2F

    content_type = "Сделай эффективный выбор шин с PROKOLESO.UA"
    result = generator_text(content_type)
    puts result
    render json: { result: result }


  end

  def total_arr_to_table

    # SeoContentText.delete_all

    h = data_json_to_hash
    number_of_repeats_for_text = 1
    number_of_repeats = 1

    ind = 0
    count_record = 0
    h.each do |key, value|
      ind += 1
      order_out = h["Block_" + ind.to_s]["order_out"].to_i
      type_text = h["Block_" + ind.to_s]["TextType"]
      content_type = h["Block_" + ind.to_s]["TextTitle"]
      array = h["Block_" + ind.to_s]["TextBody"]
      array.unshift(content_type)
      puts "content_type ==== #{content_type}"
      puts "array ==== #{array.inspect}"
      # Задаем количество повторов вариантов для всего текста в number_of_repeats_for_text
      # (количество вариантов написания каждого абзаца устанавливается в number_of_repeats)


      array.each_with_index do |el, i|
        number_of_repeats_for_text.times do
          txt = seo_phrase(el, number_of_repeats, i)
          arr_result = make_array_phrase(txt, i)
          arr_to_table(arr_result, content_type, type_text,order_out, i)
          count_record += 1
        end
      end

    end
    result = "В таблицу базы данных SeoContentText добавлены записи. === Кол-во: #{count_record}  "

    puts result
    render json: { result: result }

  end

  # задает количество вариантов написания для каждого абзаца исходного текста
  def seo_phrase(element_array, number_of_repeats, ind)
    topics = ''
    topics += element_array.to_s
    if ind > 0
      topics += "\n На тему, заданную в образце, Сделай #{number_of_repeats} вариантов текстов."
      topics += "\n Количество печатных символов в ответе может быть больше, чем количество знаков в образце."
      topics += "\n Постарайся сохранить количество ключевых слов, при этом тошнотность текста должна быть не больше 20%"
      topics += "\n Каждый вариант ответа должен состоять из одного абзаца (не использовать символ переноса каретки)"
      topics += "\n Предложения в абзаце должны быть самостоятельными по смыслу, т.е. не ссылаться на предыдущие предлжожения"
      topics += "\n Пример 1. "
      topics += "\n Неправильно: 'Шины для автомобилей различаются по типу назначения. Каждый из этих типов шин имеет особенности'. "
      topics += "\n Правильно: 'Шины для автомобилей различаются по типу назначения. Каждый тип шин имеет особенности'. "
      topics += "\n Пример 2. "
      topics += "\n Неправильно: 'Когда выбираете летнюю резину, не доверяйте подозрительно низким ценам. Подобные предложения могут быть для товаров без гарантий'. "
      topics += "\n Правильно: 'Когда выбираете летнюю резину, не доверяйте подозрительно низким ценам, подобные предложения могут быть для товаров без гарантий'. "
      topics += "\n Пример 3. "
      topics += "\n Неправильно: 'Компания ProKoleso - это надежный партнер для всех, кто ценит качество и надежность. Поэтому мы предлагаем только оригинальные автомобильные шины'. "
      topics += "\n Правильно: 'Компания ProKoleso - это надежный партнер для всех, кто ценит качество и надежность. Мы предлагаем только оригинальные автомобильные шины'. "
      topics += "\n Пример 4. "
      topics += "\n Неправильно: 'Не попадайтесь на уловки магазинов, предлагающих шины по недорогой цене. Чаще всего такие предложения скрывают низкое качество товара'. "
      topics += "\n Правильно: 'Не попадайтесь на уловки магазинов, предлагающих шины по недорогой цене. Дешевые предложения скрывают низкое качество товара'. "
      topics += "\n Пример 5. "
      topics += "\n Неправильно: 'Приобретение новой летней резины - это  залог вашей безопасности на дороге. Поэтому выбирать лучше всего проверенных поставщиков'. "
      topics += "\n Правильно: 'Приобретение новой летней резины - это  залог вашей безопасности на дороге. При покупке шин выбирать лучше всего проверенных поставщиков'. "

      # topics += "\n  "
    else
      topics += "\n Сделай из этого текста #{number_of_repeats} вариантов эффектиного заголовка для статьи. "
      topics += "\n Заголовок должен состоять из одного предложения. "
    end

    new_text = ContentWriter.new.write_seo_text(topics, 3500)['choices'][0]['message']['content'].strip
    new_text
  end

  def make_array_phrase(var_phrase, i)
    txt = var_phrase.gsub("\n\n", "\n")
    txt = txt.gsub(/\*|\#/, "")
    txt = txt.gsub(/^("|)((\d+|)(|\s+))(В|в)ариант((|\s+)(|\d+(\s+|))(\.|\:|\-))/, "")
    txt = txt.split("\n")
    txt
  end

  def arr_to_table(arr, content_type, type_text,order_out, str_number)
    arr.each do |el|
      str = el.sub(/^\d+(\.|\))\s/, '')
      str = str.gsub(/^('|")|('|")$/, '')
      replace_size_to_template(str)
      SeoContentText.create(str: str,
                            order_out: order_out,
                            type_text: type_text,
                            content_type: content_type,
                            str_number: str_number
      ) if el.present? #&& el.length > 20
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
    text = ""
    array = []
    url_params = url_shiny_hash_params

    unless max_str_number.nil?
      max_str_number += 1
      (max_str_number).times do |i|
        random_record = SeoContentText.where(content_type: content_type, str_number: i).sample
        processed_record = replace_params_w_h_r_tyre(random_record[:str], url_params)
        array << processed_record
      end
      arr_size = replace_size_tyre(array, url_params)

      first_element = array.first
      first_element.gsub('[size]', arr_size.shift&.to_s) unless arr_size.nil? || arr_size.empty?

      rest_of_array = array.drop(1).shuffle
      # задается случайный порядок предложений в абзаце
      rest_of_array.map! do |string|
        arr_size = replace_size_tyre(array, url_params) if arr_size.size == 0
        sentences = string.split(/(?<=\?|\.|!)\s/)
        shuffled_sentences = sentences.shuffle
        string_new = shuffled_sentences.join(" ")
        string_new.gsub('[size]', arr_size.shift&.to_s) unless arr_size.nil? || arr_size.empty?
        string_new
      end

      first_str = [first_element].join(" ").split(/(?<=\?|!|\.)/)[0] + "\n"
      arr_body_text = change_text_order(rest_of_array).join("\n")
      text += first_str + arr_body_text
    end
    text
  end

  def change_text_order(array)
    if array.last =~ /\?\s*$/
      last_element = array.pop
      array.unshift(last_element)
    end
    array
  end

end