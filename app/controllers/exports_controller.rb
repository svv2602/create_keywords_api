class ExportsController < ApplicationController
  include ServiceTable

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
    puts "Number of records in SeoContentTextSentence: #{SeoContentTextSentence.count}"
    puts "Number of records in SeoContentText: #{SeoContentText.count}"

    # non_zero_check_title_count = SeoContentTextSentence.where('sentence_ua = "" or sentence_ua IS NULL').count
    check_title_value_ua_count = SeoContentTextSentence.where(sentence_ua: '').count

    check_title_value2_count = SeoContentTextSentence.where('check_title = 2').count
    puts "Количество записей с check_title  равным 2: #{check_title_value2_count}"

    # ================ Временный счетчик ===============================
    now = Time.now
    total_seconds_and_minutes = now.sec + now.min * 160

    render json: { SeoContentText: "#{total_seconds_and_minutes}",
                   SeoContentTextSentence: "#{check_title_value_ua_count}"
    }
  end

  def count_records_check_title
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

  def control_records
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
    #
    render plain: "удалил весь мусор. кол-во записей с латиницей =  #{result} "

  end

  def export_xlsx
    count = 50000 # количество выгружаемых записей
    max_id = 2666514
    # @selected_records = SeoContentTextSentence.where("sentence_ua = '' and id < ?", max_id)
    # @selected_records = SeoContentTextSentence.where("sentence_ua LIKE ?", "%укра%")
    @selected_records = SeoContentTextSentence.where("sentence_ua = ''")
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


  def process_files_ua
    # добавление в записи украинского тексто
    proc_import_text_ua
    render plain: "Обновление завершено. Обработано файлов: #{result};  Обработано строк: #{j}"
  end



end
