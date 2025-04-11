class Api::V1::KeysController < ApplicationController
  #   def initialize
  #     @service = ServiceTable.new
  #   end
  include ServiceTable

  def show
    #  curl http://localhost:3000/api/v1/show
    i = 0
    h = []
    arr1 = []
    arr2 = []
    arr3 = []
    arr4 = []
    # используется с combinations_with_sorted_ratings, в коментах кол- во элементов
    # arr1 = [["Season", 1], ["Brand", 2], ['Diameter', 3], ["Addon", 4]]
    arr1 = [['Size', 1], ["Addon", 2], ['City', 3]]
    arr2 = [["Season", 1], ['Size', 3], ["Addon", 4]] # 29 элементов
    arr3 = [["Brand", 2], ['Size', 3], ["Addon", 4]]

    arr4 = []
    2.times do
      arr4 << ["Brand", "Size"]
      arr4 << ["Season", "Size", "Addon"]
      arr4 << ["Season", "Brand", "Size"]
      arr4 << ["Season", "Brand", "Diameter", "Addon"]
      arr4 << ["Season", "Size"]
    end

    4.times do
      arr4 << ["Size", "Addon"]
    end

    arr4 << ["Size"]
    arr4 << ["Size"]
    arr4 << ["Season", "Size"]
    arr4 << ["Size", "Addon"]
    arr4 << ["Season", "Diameter"]
    arr4 << ["Season", "Size"]
    arr4 << ["Brand", "Diameter", "Addon"]
    arr4 << ["Diameter", "Addon"]

    # добавить города
    rand(10) % 2 == 0 ? arr4 << ["CityUrl", "Season", "Addon"] : arr4 << ["CityUrl", "Diameter", "Addon"]

    merged_array = combinations_with_sorted_ratings(arr1) + combinations_with_sorted_ratings(arr2)
    unique_values = merged_array + combinations_with_sorted_ratings(arr3) + arr4
    # unique_values.each do |arr|
    #   record = str_hash(arr)
    #   h << { keywords: normal_str(record[:keywords]), url: record[:url] }
    #   i += 1
    # end
    unique_values.each do |arr|
      record = str_hash(arr)
      next if record.nil? # пропустить, если нет данных

      h << {
        keywords: normal_str(record[:keywords]),
        url: record[:url]
      }
      # puts h
      i += 1
    end
    puts "===================== #{unique_values.inspect}"
    puts "Количество элементов: #{i}"

    render json: {
      keyword: h.shuffle
    }

  end

  private

  def normal_str(str)
    keys = ''
    case rand(1..3)
    when 1
      keys = str.downcase
    when 2
      keys = str.downcase.capitalize
    when 3
      keys = str.capitalize
    end
    keys
  end

  def str_hash(tables_with_data)
    # массивы с именами таблиц
    table_copies = []
    # Проходим циклом по таблицам с данными
    tables_with_data.each_with_index do |table, index|
      table_copy = table + 'Copy' # Преобразуем имя таблицы-копии
      table_copies << table_copy
      copy_table_to_table_copy_if_empty(table, table_copy)
    end
    keys = extract_random_records(table_copies)
    return keys

  end

  # На входе массив таблиц и для каждой таблицы извлекает случайную
  # запись с помощью метода find_and_destroy_random_record,
  # а затем добавляет эту запись в массив result
  def extract_random_records(tables)
    rez = {}
    result = []
    city_url = ""


    url_new = url_new_params(params[:language])


    tables.each do |table_name|
      received_record = find_and_destroy_random_record(table_name)
      # record = received_record[:name]
      # puts "received_record === #{received_record}"

       if table_name == "SizeCopy"
         record = [received_record[:ww], received_record[:hh], received_record[:rr]]
       else
         record = params[:language] == "ua" ? received_record[:language] : received_record[:name]
       end
      record = received_record[:name] if table_name == "DiameterCopy"

      # if table_name == "CityCopy"
      #   record = params[:language] == "ua" ? received_record[:language] : received_record[:name]
      # end

      url_new += partial_url(table_name, received_record[:url])

      record = partial_name(table_name, record)
      table_name == "SizeCopy" ? result = result.concat(record) : result << record
      city_url = partial_url(table_name, received_record[:url]) if table_name == "CityUrlCopy"

    end


    if city_url.present?
      url_new = URI.join(url_new_params(params[:language]), city_url).to_s
    end

    # result.shuffle.join(" ")
    rez = { keywords: result.shuffle.join(" "),
            url: url_new }

  rescue => e
    puts "Error occurred: #{e.message}"
    nil

  end

  def partial_url(table_name, record_url)
    case table_name
    when "CityCopy", "AddonCopy"
      record_url = ""
    else
      record_url += "/"
    end
    record_url
  end

  def partial_name(table_name, record_name)
    case table_name
    when "DiameterCopy"
      rand(10) % 3 == 0 ? record_name = 'на ' + record_name : record_name = 'R' + record_name
    when "SizeCopy"
      record_name = size_name(record_name[0], record_name[1], record_name[2])
    else
      record_name = record_name
    end
    record_name
  end

  # обработка вариантов написания размеров
  def size_name(ww, hh, rr)
    result = []
    case rand(1..120)
    when 1..5
      result << "#{ww} #{hh}R#{rr}"       # 205 55R16
    when 6..10
      result << "#{ww}/#{hh} R#{rr}"      # 205/55 R16
    when 11..15
      result << "#{ww} #{hh} #{rr}"       # 205 55 16
    when 16..20
      result << "#{ww}/#{hh} R#{rr}"      # 205/55 R16
    when 21..25
      result << "#{ww}/#{hh} #{rr}"       # 205/55 16
    when 26..30
      result << "#{ww}/#{hh} R#{rr}"      # 205/55 R16
    when 31..40
      result << "#{ww} #{hh} R#{rr}"      # 205 55 R16
    when 41..45
      result << "#{ww}х#{hh} #{rr}"       # 205х55 16
    when 46..50
      result << "#{ww}/#{hh}/#{rr}"       # 205/55/16
    when 51..55
      result << "#{ww}х#{hh} Р#{rr}"      # 205х55 Р16 (русская "Р")
    when 56..60
      result << "#{ww}/#{hh} р#{rr}"      # 205/55 Р16 (русская "Р")
    when 61..65
      result << "#{ww}/#{hh} на #{rr}"    # 205/55 на 16
    when 66..70
      result << "#{ww}/#{hh} на R#{rr}"   # 205/55 на R16
    when 71..80
      result << "#{ww}/#{hh}R#{rr}"       # 205/55R16
    when 81..85
      result << "R#{rr} на #{ww} #{hh}"   # R16 на 205/55
    when 86..90
      result << "р#{rr} на #{ww} #{hh}"   # р16 на 205/55
    when 91..95
      result << "#{ww} #{hh} #{rr}"      # 205 55 16
    when 96..100
      result << "#{ww}/#{hh}R#{rr}"       # 205/55R16
    else
      result << "#{ww} #{hh} R#{rr}"      # 205 55 R16
    end
    result
  end

  def process_string(input_string)
    input_string.gsub("Copy", "")
  end

  # Результат массив комбинаций элементов массива с рейтингом по возврастанию
  # arr = [['а',1],['б',2],['в',3]]
  def combinations_with_sorted_ratings(arr)
    combinations = []

    # Сначала сортируем исходный массив по рейтингу
    sorted_arr = arr.sort_by { |item| item[1] }
    # puts "sorted_arr = = = #{sorted_arr}"
    # Затем создаем комбинации первых элементов, исключая те, у которых рейтинг больше 4
    (1..sorted_arr.length).each do |n|
      sorted_arr.combination(n).each do |combo|
        # Если комбинация содержит только один элемент и его рейтинг больше 4, пропускаем её
        next if combo.length == 1 && combo[0][1] > 3

        combinations << combo.map(&:first)
      end
    end

    combinations
  end


  def url_new_params(language = nil)
    base_url = "https://prokoleso.ua"
    lang_path = language.to_s == 'ua' ? '/ua' : ''
    "#{base_url}#{lang_path}/shiny/"
  end



end
