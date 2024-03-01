class ServiceTable
  # def initialize
  #   @service = ServiceTable.new
  # end
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



end