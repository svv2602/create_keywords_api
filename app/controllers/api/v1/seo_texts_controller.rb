# app/controllers/api/v1/seo_texts_controller.rb
require 'benchmark'

class Api::V1::SeoTextsController < ApplicationController
  include StringProcessing

  def json_write_for_read
    # Из текстового файла создает файл json с массивом строк, для дальнейшей подготовки к обработке
    # для запуска: внести текст, для обработки в файл lib/template_texts/text.txt
    # и выполнить
    # curl http://localhost:3000/api/v1/json_write_for_read?file=name_file
    # где параметр name_file - имя файла для записи

    template_txt_to_array_and_write_to_json
    render json: { result: "Создан файл lib/template_texts/raw_texts/#{params[:file]}.json" }
    # после обработки готовый файл нужно перенести в папку finished_texts
  end

  def seo_text
    # пример:
    # curl http://localhost:3000/api/v1/seo_text?url=https%3A%2F%2Fprokoleso.ua%2Fshiny%2Fletnie%2Fkumho%2Fw-175%2Fh-70%2Fr-13%2F

    # content_type = params[:file]
    # total_arr_to_table
    content_type = "известных_брендов"
    result = generator_text(content_type)
    puts result
    render json: { result: result }
  end

  def total_arr_to_table
    # пример: curl http://localhost:3000/api/v1/total_arr_to_table?file=ukrsina_proba
    # SeoContentText.delete_all
    content_type = params[:file]
    array = read_array_from_json_file(content_type)

    # Задаем количество повторов вариантов для всего текста в number_of_repeats_for_text
    # (количество вариантов написания каждого абзаца устанавливается в number_of_repeats)
    number_of_repeats_for_text = 5
    number_of_repeats = 10

    execution_time = Benchmark.measure do
      array.each_with_index do |el, i|
        number_of_repeats_for_text.times do
          txt = seo_phrase(el, number_of_repeats, i)
          arr_result = make_array_phrase(txt, i)
          arr_to_table(arr_result, content_type, i)
        end
      end
    end

    result = "В таблицу базы данных SeoContentText добавлены записи. Маркер - #{content_type}. \n "
    result += "Время выполнения: #{execution_time.real.round(2)} секунд. \n"
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

  def arr_to_table(arr, content_type, str_number)
    arr.each do |el|
      str = el.sub(/^\d+(\.|\))\s/, '')
      str = str.gsub(/^('|")|('|")$/, '')
      replace_size_to_template(str)
      SeoContentText.create(str: str,
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
      first_element.gsub!('[size]', arr_size.shift)

      rest_of_array = array.drop(1).shuffle

      # задается случайный порядок предложений в абзаце
      rest_of_array.map! do |string|
        arr_size = replace_size_tyre(array, url_params) if arr_size.size == 0
        sentences = string.split(/(?<=\?|\.|!)\s/)
        shuffled_sentences = sentences.shuffle
        string = shuffled_sentences.join(" ")
        string.gsub('[size]', arr_size.shift&.to_s)
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