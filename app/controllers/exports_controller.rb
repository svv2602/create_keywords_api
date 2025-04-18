class ExportsController < ApplicationController
  include ServiceTable
  include ServiceQuestion
  include IndexPageGoogle

  def control_question
    # Необходимо указать type_paragraph, 0- легковые, 1- диски, 2- грузовые
    # можно добавить проверку на наличие файла, параметр для типа вопросов - нужно ????
    # ==========================================================
    # QuestionsBlock.where(type_paragraph: 1).update_all(type_season: 1)
    # QuestionsBlock.where("type_paragraph = 1 and (question_ru like ? or question_ru like ?)","%стал%" ,"%штамп%").update_all(type_season: 2)

    # =====================================================
    type_paragraph = 1
    excel_file = "lib/text_questions/questions_base.xlsx"
    first_filling_of_table(excel_file, type_paragraph, 0) # 0 - все записи из файла
    second_filling_of_table(excel_file, type_paragraph, 7)
    render plain: "Все записи с вопросами и ответами (ru) в QuestionsBlock - обработаны  "

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
      SeoContentTextSentence.where("str_seo_text like ? AND sentence LIKE ?", "%12R20%", "%#{key}%").find_each do |content|
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
    regex = 'r22' if proc == 3

    if regex
      SeoContentText.where("str LIKE ?", "%#{regex}%").find_each do |sentence|

        sentence.attributes.each do |name, value|
          next if name == "content_type" || !value.is_a?(String)
          new_value = value.gsub(regex, '[size]')
          sentence[name] = new_value if new_value != value
        end
        sentence.save!
      end
      SeoContentTextSentence.where("sentence LIKE ?", "%#{regex}%").find_each do |sentence|
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

  def replace_size_in_seo_content_text_sentence_r22
    # Замена технических переменных  [size] на R22 в дисках
    regex = 'R22'
    records = SeoContentTextSentence.where("(sentence LIKE ? or sentence_ua LIKE ?) and id_text > 50000", "%[size]%", "%[size]%")
    records.find_each do |sentence|
      sentence.attributes.each do |name, value|
        next if name == "str_seo_text" || !value.is_a?(String)
        new_value = value.gsub('[size]', regex)
        sentence[name] = new_value if new_value != value
      end
      sentence.save!
    end
    result = "Все Ok. Обновление таблиц завершено"

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

    now = Time.now
    total_seconds_and_minutes = now.sec + now.min * 160
    countReadyReviews = total_seconds_and_minutes
    countReadyReviews20 = total_seconds_and_minutes
    countReadyReviews25 = CopyReadyReviews25.count >= 50000 ?  total_seconds_and_minutes : CopyReadyReviews25.count
    countReadyReviews30 = CopyReadyReviews30.count >= 50000 ?  total_seconds_and_minutes : CopyReadyReviews30.count
    countReadyReviews35 = CopyReadyReviews35.count >= 50000 ?  total_seconds_and_minutes : CopyReadyReviews35.count
    countReadyReviews40 = CopyReadyReviews40.count >= 50000 ?  total_seconds_and_minutes : CopyReadyReviews40.count
    countReadyReviews45 = CopyReadyReviews45.count >= 50000 ?  total_seconds_and_minutes : CopyReadyReviews45.count

    256286
    # ================ Временный счетчик ===============================


    render json: {
      countReadyReviews: countReadyReviews,
      countReadyReviews20: countReadyReviews20,
      countReadyReviews25: countReadyReviews25,
      countReadyReviews30: countReadyReviews30,
      countReadyReviews35: countReadyReviews35,
      countReadyReviews40: countReadyReviews40,
      countReadyReviews45: countReadyReviews45

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

  def control_records

    # update_seo_content_text_sentence_id_text # обновление id_text для записей с null

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
    delete_records_for_id_diski
    # result = replace_errors_sentence_diski(table) # удаление записей с ошибками

    # add_sentence_ua   # украинский перевод - !!! сделать проверку по пустому украинскому тексту!!!

    # delete_records_with_instructions

    # ==========================================================
    # clear_trash_ua # =очистка украинского текста

    render plain: "удалил весь мусор. кол-во записей с латиницей =  #{result} "

  end

  def export_xlsx
    # выгрузка из базы данных записей для дальнейшего перевода в google
    # перевод грузится в этот же файл, и потом, после обработки всех записей таблицы, все файлы грузятся обратно в базу
    count = 30000 # количество выгружаемых записей
    max_id = params[:max].to_i == 0 ? SeoContentTextSentence.where("sentence_ua = ''").maximum(:id) : params[:max].to_i

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

    max_id = (max_id - 1).to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1_').reverse

    # timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    send_data package.to_stream.read, :filename => "seo_content_text_sentences_#{max_id}.xlsx", :type => "application/xlsx"
  end

  def export_reviews_to_xlsx
    # выгрузка из базы данных записей для дальнейшего перевода в google
    # перевод грузится в этот же файл, и потом, после обработки всех записей таблицы, все файлы грузятся обратно в базу
    batch_size = 20000 # количество выгружаемых записей за одну итерацию

    # Define a directory path in Rails
    dir_path = Rails.root.join('lib', 'text_reviews_ua')

    # Create the directory if not exists
    FileUtils.mkdir_p(dir_path) unless Dir.exist?(dir_path)

    ReadyReviews.where("review_ua is null ").find_in_batches(batch_size: batch_size) do |group|
      min_id = group.first.id
      max_id = group.last.id

      package = Axlsx::Package.new
      workbook = package.workbook

      workbook.add_worksheet(name: "Content") do |sheet|
        # Заголовки колонок
        sheet.add_row ["ID", "review_ru"]

        # Запись данных
        group.each do |record|
          sheet.add_row [record.id, record.review_ru]
        end
      end

      # Save the file to directory
      package.serialize("#{dir_path}/ready_reviews_#{min_id}_to_#{max_id}.xlsx")
    end
    render plain: "Обновление завершено.  Обработано  "
  end



  def export_for_translit_xlsx
    # выгрузка данных для транслитерации
    @selected_records = TestTableCar2Model.all
    name_file = "TestTableCar2Model"
    package = Axlsx::Package.new
    workbook = package.workbook

    workbook.add_worksheet(name: name_file) do |sheet|
      # Заголовки колонок
      sheet.add_row ["ID", "name", "translit"]

      # Запись данных
      @selected_records.each do |record|
        max_year_record = TestTableCar2Kit.where(model: record.id).order(year: :desc).first
        max_year = max_year_record ? max_year_record.year.to_i : 0
        brand_name = record.brand ? record.brand.name : ''

        if max_year.to_i > 2004
          sheet.add_row [record.id, record.name, brand_name, max_year]
        end
        # sheet.add_row [record.id, record.name, Translit.convert(record.name, :russian)]
      end
    end

    # timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    send_data package.to_stream.read, :filename => "#{name_file}.xlsx", :type => "application/xlsx"
  end

  def process_files_ua
    #  ручное импортирование данных в таблицы базы данных
    # в lib/text_ua должны находится файлы только для  загрузки в одну из таблиц!!!
    # /process_files_ua?proc=1 - import_text_ua(filename) - для таблицы SeoContentTextSentence
    # /process_files_ua?proc=2 - import_questions_ua(filename) - для таблицы QuestionsBlock
    # /process_files_ua?proc=3 -  для таблицы ReadyReviews

    proc = params[:proc].to_i
    result = proc_import_text_ua(proc)

    render plain: "Обновление завершено.  Обработано  |  файлов:#{result[:files]} |  строк:#{result[:str]}"
  end

  def import_translit_auto
    # для обновления транслит по брендам и моделям автомобилей
    result = import_text_translit
    render plain: "Обновление завершено.  Обработано   строк:#{result}"

  end


  def import_reviews_without_params
    # добавление отзывов из файла "lib/reviews_templates/reviews_for_load.xlsx"

    result = import_reviews_templates
    render plain: "Обновление завершено.  Обработано   строк:#{result}"

  end

  def add_new_brand_entries
    excel_file = "lib/brands.xlsx"
    excel = Roo::Excelx.new(excel_file)

    3.times do |i|
      excel.each_row_streaming(pad_cells: true) do |row|
        name = row[i + 1]&.value
        url = row[0]&.value
        type_url = row[4]&.value
        if name.present?
          brand = Brand.find_or_create_by(name: name)
          brand.update(url: url, type_url: type_url)
        end
      end
    end
    render plain: "Обновление таблицы брендов завершено."
  end

  def control_records_reviews
    table="ready_reviews"
    # table="copy_ready_reviews25"
    replace_errors_for_reviews(table)
  end

  def copy_ready_reviews_to_main_tab
    copy_ready_reviews_to_main_tab_reviews
    render plain: "Добавление записей завершено."
  end

  # =================================================
  def size_to_index_google
    # size_to_index_google?w=175&h=70&r=13
    width = params[:w].to_i
    height = params[:h].to_i
    diameter = params[:r].to_s.gsub(/с|c|С/, 'C')

    tire_width_values = (125..345).step(10).to_a
    tire_width_values += [30, 31, 33, 35, 37, 39, 6.5, 7.5]

    tire_height_values = (10..90).step(5).to_a
    tire_height_values += (9.5..13.5).step(1).to_a

    tire_diameter_values = (12..23).step(1).to_a
    tire_diameter_values += ["12C","13C","14C","15C","16C","17C"]
    tire_diameter_values = tire_diameter_values.map(&:to_s)

    if tire_width_values.include?(width)  &&
      tire_height_values.include?(height) &&
      tire_diameter_values.include?(diameter)

      arr_url= urls_sizes_to_index(width,height,diameter)

      result = urls_to_index_google(arr_url)
      render plain: "Отправлены на индексацию url: #{result}"
    else
      render plain: "Неверное значение. Проверьте отсылаемые параметры"
    end
  end

  def article_to_index_google
    article = params[:article]
    arr_url= urls_articles_to_index(article)
    result = urls_to_index_google(arr_url)
    render plain: "Отправлены на индексацию url: #{result}"
  end



  # ========================последний end=======================

end
