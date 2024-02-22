class Api::V1::KeysController < ApplicationController

  def show
    i = 0
    h = []
    arr1 = [["Season", 1], ["Brand", 2], ['Diameter', 3], ["Addon", 4]]
    arr2 = [["Season", 1], ["Brand", 2], ['Size', 3], ["Addon", 4], ['City', 5]]
    arr3 = [["Brand", 2], ['Size', 3], ["Addon", 4]]
    # arr1 = []
    # arr2 = []
    # arr3 = []
    merged_array = combinations_with_sorted_ratings(arr1) + combinations_with_sorted_ratings(arr2)
    unique_values = merged_array.uniq + combinations_with_sorted_ratings(arr3)
    unique_values.each do |arr|
      record = str_hash(arr)
      h << {keywords: normal_str(record[:keywords]),url: record[:url]}
      i +=1
    end

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

  # Копирование таблицы, переменная - объект
  def copy_table_to_table_copy(model, model_copy)
    model.find_each do |rec|
      attributes = rec.attributes.except("id") # Исключаем атрибут идентификатора
      model_copy.create!(attributes)
    end
  end

  # Имя таблицы - текст!!!
  def copy_table_to_table_copy_if_empty(table, table_copy)
    model = table.classify.constantize
    model_copy = table_copy.classify.constantize
    if model_copy.count.zero?
      copy_table_to_table_copy(model, model_copy)
    end
  end

  # Находим и удаляем случайную запись
  # пример: find_and_destroy_random_record("Brand")
  def find_and_destroy_random_record(table)
    model = table.classify.constantize
    random_record = model.order("RANDOM()").first
    random_record&.destroy
    random_record
  end

  # На входе массив таблиц и для каждой таблицы извлекает случайную
  # запись с помощью метода find_and_destroy_random_record,
  # а затем добавляет эту запись в массив result
  def extract_random_records(tables)
    rez = {}
    result = []

    random_number = rand(1..100)

    # Проверяем, делится ли случайное число на 2
    if random_number % 2 == 0
      url_new = "https://prokoleso.ua/shiny/"
    else
      url_new = "https://prokoleso.ua/ua/shiny/"
    end

    tables.each do |table_name|
      received_record = find_and_destroy_random_record(table_name)
      record = received_record[:name]
      record = [received_record[:ww], received_record[:hh], received_record[:rr]] if table_name == "SizeCopy"

      url_new += partial_url(table_name, received_record[:url])

      record = partial_name(table_name, record)
      table_name == "SizeCopy" ? result = result.concat(record) : result << record

    end
    p url_new
    result.shuffle.join(" ")
    rez = { keywords: result.shuffle.join(" "),
            url: url_new }
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
    case rand(1..500)
    when 1..10, 210..215
      # 2055516
      result << "#{ww}#{hh}#{rr}"
    when 11..20, 216..260
      # 205/55R16
      result << "#{ww}/#{hh}R#{rr}"
    when 21..30, 261..300
      # 205 55R16
      result << "#{ww} #{hh}R#{rr}"
    when 31..40, 301..330
      # 205 55р16
      result << "#{ww} #{hh}р#{rr}"
    when 41..50, 331..350
      # 205 5516
      result << "#{ww} #{hh}#{rr}"

    when 51..60, 351..370
      result << "#{ww} #{hh}"
      result << "#{rr}"
    when 61..70, 371..380
      result << "#{ww} #{hh}"
      result << "р#{rr}"
    when 71..80, 381..410
      result << "#{ww} #{hh}"
      result << "r#{rr}"
    when 81..90, 381..450
      result << "#{ww} #{hh}"
      result << "R#{rr}"
    when 91..100
      result << "#{ww}/#{hh}"
      result << "#{rr}"
    when 101..110
      result << "#{ww}/#{hh}"
      result << "р#{rr}"
    when 111..120, 451..470
      result << "#{ww}/#{hh}"
      result << "r#{rr}"
    when 121..130, 471..490
      result << "#{ww}/#{hh}"
      result << "R#{rr}"

    when 131..140
      result << "#{ww}х#{hh}"
      result << "#{rr}"
    when 141..150
      result << "#{ww}х#{hh}"
      result << "р#{rr}"
    when 151..160
      result << "#{ww}x#{hh}"
      result << "r#{rr}"
    when 161..170
      result << "#{ww}x#{hh}"
      result << "R#{rr}"

    when 171..180
      result << "#{ww}х#{hh}"
      result << "на #{rr}"
    when 181..190
      result << "#{ww}х#{hh}"
      result << "Р#{rr}"
    when 191..200
      result << "#{ww}/#{hh}"
      result << "Р#{rr}"
    when 201..210
      result << "#{ww} #{hh}"
      result << "Р#{rr}"
    else
      result << "#{ww}/#{hh}R#{rr}"
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

end
