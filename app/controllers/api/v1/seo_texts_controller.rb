# app/controllers/api/v1/seo_texts_controller.rb

class Api::V1::SeoTextsController < ApplicationController
  include StringProcessing


  def json_write_for_read
    # Из текстового файла создает файл json с массивом строк, для дальнейшей подготовки к обработке
    # для запуска: внести текст, для обработки в файл lib/template_texts/text.txt
    # и выполнить curl http://localhost:3000/api/v1/json_write_read?file=name_file
    # где параметр name_file - имя файла для записи
    file_path_out = params[:file]
    template_txt_to_array_and_write_to_json(file_path_out)
    render json: { result: "Создан файл #{file_path_out}.json" }
    # после обработки готовый файл нужно перенести в папку finished_texts
  end

  def seo_text
    # выполнить curl http://localhost:3000/api/v1/json_write_read?file=name_file
    # где параметр name_file - имя подготовленного json-файла в папке lib/template_texts/finished_texts

    # content_type = params[:file]
    total_arr_to_table
    result = "Ok!!!"
    # content_type = "ВТОРОЙ ТЕКСТ"
    # result = generator_text(content_type)
    puts result
    render json: { result: result }
  end

  def total_arr_to_table
    SeoContentText.delete_all
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
    number_of_repeats_for_text = 1
    number_of_repeats = 1
    sch = 0
    array.each_with_index do |el, i|
      number_of_repeats_for_text.times do
        puts "ВХОДЯЩАЯ ФРАЗА #{i}:==   #{el}"
        txt = seo_phrase(el,number_of_repeats)
        puts "ФРАЗА:   #{txt}"
        arr_result = make_array_phrase(txt, i)
        arr_to_table(arr_result, content_type, i)
        # sch += number_of_repeats
      end
    end
    result = "В таблицу базы данных SeoContentText добавлены #{sch} записей. Маркер - #{content_type}"
    puts result
    render json: { result: result }

  end

  # задает количество вариантов написания для каждого абзаца исходного текста
  def seo_phrase(element_array, number_of_repeats)
    topics = ''
    topics += element_array.to_s
    topics += "\n Сделай #{number_of_repeats} вариантов рерайта этого текста"

    new_text = ContentWriter.new.write_seo_text(topics, 3500)['choices'][0]['message']['content'].strip
    new_text
  end

  def make_array_phrase(var_phrase, i)
    txt = var_phrase.gsub("\n\n", "\n")
    if i == 0
      txt = txt.split("\n").first
    else
      txt = txt.gsub("\n", " ")
    end
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
      ) if el.present? && el.length > 20
    end
  end

  def replace_size_tyre(array_of_string)
    ww = "205"
    hh = "55"
    rr = "16"
    arr_size = []
    size_count = array_of_string.count { |string| string.include?("[size]") }
    size_count.times do |i|
      arr_size << arr_size_name_min(ww, hh, rr, i)
    end
    arr_size

  end

  def generator_text(content_type)

    # количество абзацев в выбранном типе текста
    max_str_number = SeoContentText.where(content_type: content_type).maximum(:str_number)
    text = ""
    array = []
    (max_str_number).times do |i|
      random_record = SeoContentText.where(content_type: content_type, str_number: i).sample
      array << random_record[:str]
    end
    arr_size = replace_size_tyre(array)

    first_element = array.first
    first_element.gsub!('[size]', arr_size.shift)

    rest_of_array = array.drop(1).shuffle

    # задается случайный порядок предложений в абзаце
    rest_of_array.map! do |string|
      sentences = string.split(/(?<=\?|\.|!)\s/)
      shuffled_sentences = sentences.shuffle
      string = shuffled_sentences.join(" ")
      string.gsub!('[size]', arr_size.shift)
    end

    first_str = [first_element].join(" ").split(/(?<=\?|!|\.)/)[0] + "\n"
    text += +first_str + rest_of_array.join("\n")
    text
  end

end