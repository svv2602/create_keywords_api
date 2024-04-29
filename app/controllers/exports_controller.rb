class ExportsController < ApplicationController
  include ServiceTable
  include ServiceQuestion

  def control_question
    # Необходимо указать type_paragraph, 0- легковые, 1- диски, 2- грузовые
    type_paragraph = 2
    first_filling_of_table(type_paragraph, 0) # 0 - все записи из файла
    second_filling_of_table(type_paragraph, 7)
  end

  def replace_name_brand_total
    #  Замена брендов в текстах для грузовых шин
    hash_replace = {
      "Pirelli" => "Aeolus",
      "Nokian Tyres" => "Satoya",
      "Nokian" => "Satoya",
      "Goodyear" => "Hankook",
      "Giti Tire" => "Rosava",
      "BFGoodrich" => "Kumho",
      "BF Goodrich" => "Kormoran",
      "Apollo" => "Fulda",
      "Cooper" => "Lassa",
      "General Tire" => "Barum"
    }
    replace_name_brand_in_seo_content_text(hash_replace)
    replace_name_brand_in_seo_content_text_sentence(hash_replace)
    render plain: "Сделана замена брендов"
  end
  def replace_name_brand_in_seo_content_text(hash_replace)

    hash_replace.each do |key, value|
      SeoContentText.where("order_out = 2 AND str LIKE ?", "%#{key}%").find_each do |content|
        new_str = content.str.gsub(/#{key.to_s}/i, value.to_s)
        content.update(str: new_str)
      end
    end
  end

  def replace_name_brand_in_seo_content_text_sentence(hash_replace)
    hash_replace.each do |key, value|
      SeoContentTextSentence.where("str_seo_text like ? AND sentence LIKE ?", "%12R20%","%#{key}%").find_each do |content|
        new_sentence = content.sentence.gsub(/#{key.to_s}/i, value.to_s)
        new_sentence_ua = content.sentence_ua.gsub(/#{key.to_s}/i, value.to_s)
        content.update(sentence: new_sentence, sentence_ua: new_sentence_ua)
        content.reload
      end
    end
  end

  def replace_text_in_seo_content_text_sentence
    # Замена технических переменных на [size]
    proc = params[:proc].to_i
    regex = '12R20' if proc == 1
    regex = 'R22' if proc == 2

    if regex
      SeoContentText.find_each do |sentence|

        sentence.attributes.each do |name, value|
          next if name == "content_type" || !value.is_a?(String)
          new_value = value.gsub(regex, '[size]')
          sentence[name] = new_value if new_value != value
        end
        sentence.save!
      end
      SeoContentTextSentence.find_each do |sentence|
        sentence.attributes.each do |name, value|
          next if name == "str_seo_text" || !value.is_a?(String)
          new_value = value.gsub(regex, '[size]')
          sentence[name] = new_value if new_value != value
        end
        sentence.save!
      end
      result = "Все Ok. Обновление таблиц завершено"
    else
      result = "Не выбран параметр proc. Обновление таблиц отменено"
    end

    puts result
    render plain: result

  end

  def download_database
    send_file(
      "#{Rails.root}/storage/development.sqlite3",
      filename: "database_backup.sqlite3",
      type: "application/x-sqlite3"
    )
  end

  def export_text
    records = SeoContentText.all.as_json
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    send_data records.to_json, filename: "export_text_#{timestamp}.json"
  end

  def export_sentence
    records = SeoContentTextSentence.all.as_json
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    send_data records.to_json, filename: "export_sentence_#{timestamp}.json"
  end

  def clear_tables_texts

    # case params[:table].to_i
    # when 1
    #   SeoContentText.delete_all
    # when 2
    #   SeoContentTextSentence.delete_all
    # when 12
    #   SeoContentTextSentence.delete_all
    #   SeoContentText.delete_all
    # end
    render plain: "Все удалено "
  end

  def count_records
    # вывод количества записей в таблицах - сделан для крона (запуск процедуры если количество записей не меняетс)
    seo_content_text_last_id = SeoContentTextSentence.last.id
    puts "Number of records in SeoContentText: #{seo_content_text_count}"

    seo_content_text_sentence_last_id_text = SeoContentTextSentence.last.id_text
    puts "Number of records in SeoContentTextSentence: #{seo_content_text_sentence_count}"

    check_title_value2_count = SeoContentTextSentence.where('check_title = 2').count
    puts "Количество записей с check_title  равным 2: #{check_title_value2_count}"



    # ================ Временный счетчик ===============================
    now = Time.now
    total_seconds_and_minutes = now.sec + now.min * 160

    render json: { SeoContentText: "#{seo_content_text_last_id}",
                   SeoContentTextSentence: "#{seo_content_text_sentence_last_id_text}"
    }
  end

  def count_records_check_title
    # контроль количества текстов для загрузки
    selected_records = SeoContentTextSentence.where("str_number != 0 AND num_snt_in_str = 0 AND check_title = 0")
    non_zero_check_title_count = selected_records.count
    result = "Количество записей с check_title  равным 0: #{non_zero_check_title_count}"
    puts result
    render plain: result

  end

  def readme
    readme_file_path = Rails.root.join('README.md')
    readme_content = File.read(readme_file_path)
    render plain: readme_content
  end

  def update_seo_content_text_sentence_id_text
    # Находим все записи, где id_text is null
    SeoContentTextSentence.where(id_text: nil).find_each do |sentence|
      # Находим соответствующую запись в SeoContentText
      seo_content_text = SeoContentText.find_by(content_type: sentence.str_seo_text)

      # Обновляем id_text, если найдена соответствующая запись
      sentence.update(id_text: seo_content_text.id, type_text: seo_content_text.type_text) if seo_content_text
    end
  end

  def control_records
    update_seo_content_text_sentence_id_text
    result = ""
    # сделать очистку таблиц
    table = 'seo_content_text_sentences'

    # SeoContentTextSentence.update_all(check_title: 0)
    # ==========================================================
    # 0 часть - исправить ошибку с заголовкоками
    # ==========================================================
    # заменяем ошибочные заголовки, - единарозовое использование
    # исправление ошибки с индексами 0,0 в sentence
    # перерабатывает строки с индексами 0,n - из заголовков в текст
    # replace_errors_title_sentence -- !! не запускать не подумав
    # ==========================================================

    # обязательная часть, проверенная
    # ==========================================================
    # 1 часть
    # ==========================================================

    # remove_empty_sentences(table) # удаление пустых записей
    # result = replace_errors_size(table) # удаление записей с ошибками
    # repeat_sentences_generation # дополнение до 25
    # ==========================================================
    # 2 часть
    # ==========================================================
    # result = replace_errors_size(table) # удаление записей с ошибками
    # add_sentence_ua   # украинский перевод - !!! сделать проверку по пустому украинскому тексту!!!

    # ==========================================================

    # Заполнение таблицы
    # TextError.delete_all
    # excel_file = "lib/text_errors.xlsx"
    # excel = Roo::Excelx.new(excel_file)
    # i = 0
    # excel.each_row_streaming(pad_cells: true) do |row|
    #   begin
    #     i += 1
    #     line = row[0]&.value
    #     type_line = row[1]&.value
    #     line_ua = row[2]&.value
    #     line_ua = line_ua.gsub("​​",'')
    #     puts "№ #{i}    type_line === #{line} "
    #     TextError.create(line: line, line_ua: line_ua, type_line: type_line) if line.present?
    #   rescue StandardError => e
    #     puts "Error on row #{i}: #{e.message}"
    #     next
    #   end
    # end

    # delete_records_with_instructions

    # ==========================================================
    # clear_trash_ua # =очистка украинского текста

    render plain: "удалил весь мусор. кол-во записей с латиницей =  #{result} "

  end

  def export_xlsx
    # выгрузка из базы данных записей для дальнейшего перевода в google
    # перевод грузится в этот же файл, и потом, после обработки всех записей таблицы, все файлы грузятся обратно в базу
    count = 50000 # количество выгружаемых записей
    max_id = params[:max].to_i
    # max_id = 1534655
    @selected_records = SeoContentTextSentence
    # .where("sentence like ? and sentence_ua not like ?", "%size%", "%size%")
                          .where("sentence_ua = '' and id < ?", max_id)
                          .order(id: :desc)
                          .limit(count)

    package = Axlsx::Package.new
    workbook = package.workbook

    workbook.add_worksheet(name: "Seo Content Text Sentences") do |sheet|
      # Заголовки колонок
      sheet.add_row ["ID", "Sentence"]

      # Запись данных
      @selected_records.each do |record|
        sheet.add_row [record.id, record.sentence]
      end
    end

    max_id = max_id.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1_').reverse

    # timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    send_data package.to_stream.read, :filename => "seo_content_text_sentences_#{max_id}.xlsx", :type => "application/xlsx"
  end

  def export_questions_to_xlsx
    count = 50000 # количество выгружаемых записей
    max_id = 2666514
    # @selected_records = SeoContentTextSentence.where("sentence_ua = '' and id < ?", max_id)
    # @selected_records = SeoContentTextSentence.where("sentence_ua LIKE ?", "%укра%")
    # @selected_records = SeoContentTextSentence.where("sentence_ua = ''")
    @selected_records = QuestionsBlock
                          .where("answer_ua = ''")
                          .order(id: :desc)
                          .limit(count)

    package = Axlsx::Package.new
    workbook = package.workbook

    workbook.add_worksheet(name: "Questions") do |sheet|
      # Заголовки колонок
      sheet.add_row ["ID", "Questions", "Answer"]

      # Запись данных
      @selected_records.each do |record|
        sheet.add_row [record.id, record.question_ru, record.answer_ru]
      end
    end

    # timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    send_data package.to_stream.read, :filename => "seo_question_ru.xlsx", :type => "application/xlsx"
  end

  def process_files_ua
    #  ручное импортирование данных в таблицы базы данных
    # в lib/text_ua должны находится файлы только для  загрузки в одну из таблиц!!!
    # /process_files_ua?proc=1 - import_text_ua(filename) - для таблицы SeoContentTextSentence
    # /process_files_ua?proc=2 - import_questions_ua(filename) - для таблицы QuestionsBlock

    proc = params[:proc].to_i
    proc_import_text_ua(proc)

    render plain: "Обновление завершено.  Обработано строк: #{j}"
  end

  def add_new_brand_entries
    # обновление таблицы брендов
    excel_file = "lib/brands.xlsx"
    excel = Roo::Excelx.new(excel_file)

    3.times do |i|
      excel.each_row_streaming(pad_cells: true) do |row|
        name = row[i + 1]&.value
        url = row[0]&.value
        Brand.find_or_create_by(name: name) do |brand|
          brand.url = url
        end if name.present?
      end
    end
    render plain: "Обновление таблицы брендов завершено."
  end

  # ========================последний end=======================

end
