module ServiceTable

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


  def duplicated_in_data_json?(file_path)
    # require 'json'

    # Предположим, что ваш файл находится в этом местоположении
    # file_path = 'path_to_your_file.json'

    # Разбираем JSON из файла
    data = JSON.parse(File.read(file_path))

    # Извлекаем значения "TextTitle"
    titles = data.values.map { |block| block["TextTitle"] }

    # Проверяем, уникальны ли значения "TextTitle"
    titles_are_unique = titles.uniq.length == titles.length

    if titles_are_unique
      puts 'Все значения TextTitle - unique'
      result = true
    else
      puts 'Некоторые значения TextTitle - дублированы'
      # Извлекаем значения "TextTitle"
      titles = data.values.map { |block| block["TextTitle"] }

      # Группируем по значениям и фильтруем, оставляя только те, которые встречаются более 1 раза
      duplicates = titles.group_by { |v| v }.select { |k, v| v.size > 1 }.keys

      duplicates.each do |duplicate|
        puts "Duplicate title: #{duplicate}"
      end
      result = false
    end
    result
  end


end