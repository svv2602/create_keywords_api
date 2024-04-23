module StringProcessingServices

  def array_after_error_from_seo_content_text(order_out = 0, all_records = 0 )
    # all_records - количество обрабатываемых записей: 1 - все записи, 0- с последнего id текста в SeoContentTextSentence

    all_records = params[:all_records] if params.key?(:all_records)

    # records = SeoContentText.all
    records = SeoContentText.where(order_out: order_out)
    if all_records == 1
      filtered_records = records
    else
      # id текста в  последняя запись по предложениям
      # id_last_text_in_table_sentence = (SeoContentTextSentence.last&.id_text || 0)
      id_last_text_in_table_sentence = (SeoContentTextSentence.maximum(:id_text) || 0)
      puts "id_last_text_in_table_sentence ====== #{id_last_text_in_table_sentence}"
      id_record_content_text_in_table_text = (SeoContentText.where(order_out: order_out).find_by(id: id_last_text_in_table_sentence)&.id || SeoContentText.where(order_out: order_out).first&.id)
      puts "id_record_content_text_in_table_text ====== #{id_record_content_text_in_table_text}"
      # filtered_records = records.drop_while { |record| record.id < id_record_content_text_in_table_text }
      filtered_records = SeoContentText.where("id >= ? AND order_out = ?", id_record_content_text_in_table_text, order_out)
    end

    filtered_records

  end

  def array_after_error_from_json(filename)
    # Данный метод array_after_error_from_json обрабатывает содержимое JSON-файла и возвращает новый хэш,
    # содержащий только те элементы, которые идут после последнего обработанного элемента
    hash_new = {}
    hash = data_json_to_hash(filename)
    return hash_new unless hash # return early if hash is nil

    content_last_element_hash = last_element_hash_json(hash)
    return hash_new unless content_last_element_hash # return early if content_last_element_hash is nil

    last_content_type = ""

    last_rec = SeoContentText.order(:created_at).last
    last_content_type = last_rec.content_type if last_rec

    # Если last_content_type все еще пуст, возвратить полный исходный хэш
    return hash if last_content_type.empty?

    if last_content_type && last_content_type != content_last_element_hash
      delete_flag = false

      hash_new = hash.delete_if do |key, value|
        if value["TextTitle"] == last_content_type
          delete_flag = true
        end
        !delete_flag
      end

    end

    hash_new
  end

  def last_element_hash_json(hash)
    text_title = ''
    last_key_value_pair = hash.to_a.last
    if last_key_value_pair
      sub_hash = last_key_value_pair[1]
      text_title = sub_hash["TextTitle"]
    end
    text_title
  end

  # Доработать удаление мусорных записей AI
  def delete_all_trash_records_ai
    # exclude_words = arr_name_brand_uniq
    # SeoContentText.all.each do |record|
    #   SeoContentText.where(id: record.id).destroy_all if check_trash_words_invalid?(record.str, exclude_words)
    #   # puts record.str if is_the_percent_of_Latin_chars_invalid?(record.str)
    # end
    #
    # SeoContentTextSentence.all.each do |record|
    #   SeoContentTextSentence.where(id: record.id).destroy_all if check_trash_words_invalid?(record.sentence, exclude_words)
    # end
  end

  def delete_record_with_trash(text)
    SeoContentText.where(str: text).delete_all
    SeoContentTextSentence.where(sentence: text).delete_all
  end

  def arr_name_brand_uniq
    # извлечения уникальных значений из поля url
    unique_urls = Brand.pluck(:url).uniq
    # преобразовать каждый URL в массив слов
    words_array = unique_urls.map { |url| url.split("/") }.flatten.uniq
    exclude_words = words_array.join("|") # преобразуем массив слов в строку, разделенную символом '|'
    exclude_words
  end

  def check_trash_words_invalid?(text, exclude_words)
    # is_the_percent_of_Latin_chars_invalid? in delete_all_trash_records_ai
    result = 0
    # проверка на допустимое наличие букв латинского алфавита (% от общего количества знаков)
    result += 1 if percent_of_latin_chars(text, exclude_words) > 10
    # result += 1 if trash_words(text) == 1
    result
  end

  def trash_words(text)

    marker1 = "копирайт"
    marker2 = "моск(в|ов)|росс"
    regexp_string = "(?:#{marker1}|#{marker2})"
    regexp = Regexp.new(regexp_string, 1)

    percentage = text =~ regexp ? 1 : 0

    percentage
  end

  def percent_of_latin_chars(text, exclude_words = '')
    # список брендов
    # exclude_words по умолчанию "", для проверки с наименованиями брендов передавать параметр = arr_name_brand_uniq
    percentage = 0
    # Подсчет латинских символов в тексте
    # регулярное для маркировки
    marker = "Z|W|Y|\(Y\)|ZR|XL|Reinforced|SL|Standard\sLoad|AS|All-Season|AT|All\-Terrain|MT|M\+S|3PMSF|M/S|LT|P|C|ST|RF|DOT|ECE|ISO|UTQG|M&S|ATP|AWD"


    # Создаем регулярное выражение, объединяя все слова и регулярные выражения, из которых нужно избавиться
    regexp_string = "\\b(?:size|prokoleso|#{exclude_words.split(' ').join("|")}|ua|#{marker})\\b"
    regexp = Regexp.new(regexp_string, 1)

    filtered_text = text.gsub(regexp, '') # удаляем указанные слова из текста
    filtered_text = filtered_text.gsub(/(R|r)(|\s*)\d+/, '')
    filtered_text = filtered_text.gsub(/(R|r|c|x|o|e|a)/, '')
    filtered_text = filtered_text.gsub(/call|visa|Doudlestar|vs|TOP|MasterCard|liqpay/i, '')
    filtered_text = filtered_text.gsub(/sms|pos|mud and snow|Visa\/MasterCard|must\-have|online/i, '')

    latin_letters = filtered_text.scan(/[a-zA-Z]/).size
    total_chars = text.gsub(/\s+/, "").size
    percentage = (latin_letters.to_f / total_chars) * 100 if total_chars > 0

    # puts "Percentage of Latin letters: #{percentage.round(2)}%"
    percentage

  end

end