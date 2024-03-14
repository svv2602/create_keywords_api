# app/controllers/api/v1/seo_texts_controller.rb

class Api::V1::SeoTextsController < ApplicationController
  include StringProcessing

  def json_write_for_read
    # Из текстового файла создает файл json с массивом строк, для дальнейшей подготовки к обработке
    # для запуска: внести текст, для обработки в файл lib/template_texts/text.txt
    # и выполнить curl http://localhost:3000/api/v1/json_write_for_read?file=name_file
    # где параметр name_file - имя файла для записи
    file_path_out = params[:file]
    template_txt_to_array_and_write_to_json(file_path_out)
    render json: { result: "Создан файл #{file_path_out}.json" }
    # после обработки готовый файл нужно перенести в папку finished_texts
  end

  def seo_text
    # пример: curl http://localhost:3000/api/v1/seo_text?url=https%3A%2F%2Fprokoleso.ua%2Fshiny%2Fletnie%2Fkumho%2Fw-175%2Fh-70%2Fr-13%2F

    # content_type = params[:file]
    # total_arr_to_table
    result = "Ok!!!"
    content_type = "ukrsina_proba"
    result = generator_text(content_type)
    puts result
    render json: { result: result }
  end

  def total_arr_to_table
    # пример: curl http://localhost:3000/api/v1/total_arr_to_table?file=ukrsina_proba
    # SeoContentText.delete_all
    content_type = params[:file]
    array = read_array_from_json_file(content_type)
    # array = ["Купить шины 175/70 R13 в Киеве и Украине",
    #          "Желаете обновить шины 175/70 R13 для вашего автомобиля? Тогда обратите внимание на широкий выбор моделей шин на сайте Prokoleso.ua. У нас вы найдете разнообразие вариантов от ведущих производителей, подходящих как для повседневных поездок, так и для экстремальных условий.",
    #          "Каталог шин 175/70 R13 на сайте Prokoleso.ua порадует вас разнообразием предложений. Вы сможете выбрать сезонность, индексы скорости и нагрузки, а также рисунок протектора, соответствующий вашим потребностям и требованиям к безопасности и комфорту. У нас представлены и премиум, и бюджетные варианты, чтобы каждый клиент смог выбрать оптимальное решение.",
    #          "При выборе шин 175/70 R13 важно учитывать множество факторов. И наш сайт поможет вам в этом. Удобный фильтр позволяет быстро найти нужные варианты, а простой интерфейс делает процесс выбора максимально комфортным. Мы ценим ваше время, поэтому сделаем покупку шин простой и приятной процедурой.",
    #          "Помимо выбора и покупки шин, на Prokoleso.ua вы можете воспользоваться дополнительными возможностями. Сравните различные модели и бренды шин 175/70 R13, изучив отзывы клиентов, чтобы принять обоснованное решение. А если у вас остались вопросы, наши специалисты всегда готовы дать вам профессиональную консультацию.",
    #          "Важно помнить, что правильный выбор и покупка шин 175/70 R13 имеют большое значение для вашей безопасности на дороге. Поэтому не теряйте времени, приобретайте качественную резину на Prokoleso.ua уже сегодня и наслаждайтесь комфортными и безопасными поездками в Киеве и по всей Украине."
    # ]
    # content_type = "ВТОРОЙ ТЕКСТ"

    # Задаем количество повторов вариантов для всего текста в number_of_repeats_for_text
    # (количество вариантов написания каждого абзаца устанавливается в number_of_repeats)
    number_of_repeats_for_text = 2
    number_of_repeats = 2
    sch = 0
    array.each_with_index do |el, i|
      number_of_repeats_for_text.times do
        puts "ВХОДЯЩАЯ ФРАЗА #{i}:==   #{el}"
        txt = seo_phrase(el, number_of_repeats, i)
        puts "ФРАЗА:   #{txt}"
        arr_result = make_array_phrase(txt, i)
        arr_to_table(arr_result, content_type, i)
        sch += number_of_repeats
      end
    end
    result = "В таблицу базы данных SeoContentText добавлены #{sch} записей. Маркер - #{content_type}"
    puts result
    render json: { result: result }

  end

  # задает количество вариантов написания для каждого абзаца исходного текста
  def seo_phrase(element_array, number_of_repeats, ind)
    topics = ''
    topics += element_array.to_s
    if ind > 0
      topics += "\n На тему, заданную в образце, Сделай #{number_of_repeats} вариантов текстов."
      topics += "\n Количество печатных символов в ответе должно быть близким к количеству знаков в образце"
      topics += "\n постараться сохранить количество ключевых слов, главное - получить эффективный уникальный SEO-текст"
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
    # if i == 0
    #   # txt = txt.split(/\n|\.|\?|\!/).first
    #   elements = txt.split(/\n|\.|\?|\!/)
    #   elements.find { |element| element.length > 20 }
    #
    # else
    #   # txt = txt.gsub("\n", " ")
    #   txt = txt.gsub(/^("|)((\d+|)(|\s+))(В|в)ариант((|\s+)(|\d+(\s+|))(\.|\:|\-))/,"")
    # end
    txt = txt.gsub(/^("|)((\d+|)(|\s+))(В|в)ариант((|\s+)(|\d+(\s+|))(\.|\:|\-))/, "")
    txt = txt.split("\n")
    txt
  end

  def arr_to_table(arr, content_type, str_number)
    arr.each do |el|
      str = el.sub(/^\d+(\.|\))\s/, '')
      replace_size_to_template(str)
      SeoContentText.create(str: str,
                            content_type: content_type,
                            str_number: str_number
      ) if el.present? #&& el.length > 20
    end
  end

  def replace_size_tyre(array_of_string,url_params)
    arr = []
    size_count = array_of_string.count { |string| string.include?("[size]") }
    size_count.times do |i|
      arr << arr_size_name_min(url_params[:tyre_w], url_params[:tyre_h], url_params[:tyre_r], i)
    end
    arr
  end

  def replace_params_w_h_r_tyre(str,url_params)
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

      (max_str_number).times do |i|
        random_record = SeoContentText.where(content_type: content_type, str_number: i).sample
        processed_record = replace_params_w_h_r_tyre(random_record[:str],url_params)
        array << processed_record
      end
      arr_size = replace_size_tyre(array,url_params)

      first_element = array.first
      first_element.gsub!('[size]', arr_size.shift)

      rest_of_array = array.drop(1).shuffle

      # задается случайный порядок предложений в абзаце
      rest_of_array.map! do |string|
        arr_size = replace_size_tyre(array,url_params) if arr_size.size == 0
        sentences = string.split(/(?<=\?|\.|!)\s/)
        shuffled_sentences = sentences.shuffle
        string = shuffled_sentences.join(" ")
        string.gsub('[size]', arr_size.shift&.to_s)
      end

      first_str = [first_element].join(" ").split(/(?<=\?|!|\.)/)[0] + "\n"
      text += +first_str + rest_of_array.join("\n")
    end
    text
  end

end