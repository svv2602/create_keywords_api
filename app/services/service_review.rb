# app/services/service_review.rb
require_relative '../../app/services/dictionaries/const_reviews'
module ServiceReview

  def array_params
    # результатом будет вспомагательный файл с хешами массивов, содержащих варианты оценки для  каждого свойства
    path = Rails.root.join('app', 'services', 'dictionaries', 'combination_results.rb')
    array2 = [1, -1, 0]

    # формирование хеша для зимних шин
    array1 = PROPERTIES_TIRES
    n = array1.length
    # Генерируем все возможные комбинации оценок
    all_combinations = array2.repeated_permutation(n).to_a

    positive_combinations = all_combinations.select { |combination| combination.sum > 0 }
    negative_combinations = all_combinations.select { |combination| combination.sum < 0 }
    neutral_combinations = all_combinations.select { |combination| combination.sum == 0 }

    result_hash = {
      positive: positive_combinations,
      negative: negative_combinations,
      neutral: neutral_combinations
    }

    File.open(path, "w") do |file|
      file.write("COMBINATIONS_WINTER = #{result_hash.inspect}")
    end

    # формирование хеша для летних шин
    array1 = array1.slice(0, 4)
    n = array1.length

    all_combinations = array2.repeated_permutation(n).to_a

    positive_combinations = all_combinations.select { |combination| combination.sum > 0 }
    negative_combinations = all_combinations.select { |combination| combination.sum < 0 }
    neutral_combinations = all_combinations.select { |combination| combination.sum == 0 }

    result_hash = {
      positive: positive_combinations,
      negative: negative_combinations,
      neutral: neutral_combinations
    }

    File.open(path, "a") do |file|
      file.write("COMBINATIONS_SUMMER = #{result_hash.inspect}")
    end

  end

  def topics_array
    arr = []

    sizes = SIZES
    brands = BRANDS
    models = MODELS
    cars = AUTO
    genders = GENDERS
    seasons = SEASONS
    types_review = TYPES_REVIEW

    sizes.each do |size|
      brands.each do |brand|
        models.each do |model|
          cars.each do |car|
            genders.each do |gender|
              seasons.each do |season|
                types_review.each do |type_review|
                  str = ''
                  str += "Тип отзыва: #{type_review}\n"
                  str += "Автор отзыва: #{gender}\n" unless gender == ""
                  str += "Размер шины: #{size}\n" unless size == ""
                  str += "Бренд: #{brand}\n" unless brand == ""
                  str += "Модель шины: #{model}\n" unless model == ""
                  str += "Применимость шины (сезонность): #{season}\n" unless season == ""
                  str += "Использовались на автомобиле: #{car}\n" unless car == ""
                  params = {
                    gender: gender,
                    season: season,
                    type_review: type_review,
                    main_string: str
                  }
                  arr << params
                end
              end
            end
          end
        end
      end
    end

    arr
  end

  def array_additional_information_for_text_generation(season, types_review)
    # получаем массив с массивами оценок по свойствам
    hash = season == "летние" ? COMBINATIONS_SUMMER : COMBINATIONS_WINTER
    key = case types_review
          when "положительный"
            :positive
          when "негативный"
            :negative
          when "нейтральный"
            :neutral
          end
    hash[key]
  end

  def str_additional_information_for_text_generation(ratings_array)
    # создается хеш с оценками и строкой для генерации текста
    # ratings_array = [-1, 0, 0,0]
    params = {}
    str = "Автор отзыва сделал дополнительно оценку свойств шины:\n"
    PROPERTIES_TIRES.each_with_index do |el, i|
      if i < ratings_array.size && ratings_array[i] != 0
        rating = ratings_array[i] > 0 ? "хорошо" : "плохо"
        str += "#{el}: #{rating}\n"
      end
      param_key = "param#{i + 1}".to_sym
      params[param_key] = ratings_array[i]
    end
    params[:additional_string] = str
    params
  end

  def generating_records_and_writing_to_table_review
    # Review.delete_all
    i = 0
    array_hash_topics = topics_array
    array_hash_topics.each do |hash_topic|
      season = hash_topic[:season]
      types_review = hash_topic[:type_review]
      arrays = array_additional_information_for_text_generation(season, types_review)
      arrays.each do |array|
        hash_additional_information = str_additional_information_for_text_generation(array)
        merged_hash = hash_topic.merge(hash_additional_information)
        add_new_record_to_model('Review', merged_hash)
        i += 1
      end
    end
    return "Добавлено записей: #{i}"
  end

  def select_texts_for_generating_reviews
    min_id = params[:min].to_i
    max_id = params[:max].to_i

    max_id = 25000 if max_id == 0
    min_id = ReadyReviews.where("id_review >= ? and id_review < ?", min_id, max_id).order(id_review: :desc).first.id_review if min_id == 0

    puts "2 min_id = #{min_id}"
    puts "2 max_id = #{max_id}"

    records = max_id.nil? ? Review.all : Review.where("id >= ? and id < ?", min_id, max_id)
    result = generating_texts_and_writing_to_tables(records)
    result
  end

  def generating_texts_and_writing_to_tables(records)

    # max_id = ReadyReviews.last&.id_review
    # records = max_id.nil? ? Review.all : Review.where("id >= ?", max_id)
    i = 0
    str_errors_template = "Сделай в отзыве несколько грамматических ошибок в словах на кириллице так, как это мог бы сделать человек\n"
    records.each do |record|
      puts "MAIN_METOD records Review id = #{record.id}"
      TEXT_LENGTH.each_with_index do |arr_review_length, index|
        puts "TEXT_LENGTH records Review id = #{record.id}"
        count_repeat = TEXT_LENGTH.size - index
        count_repeat.times do
          new_hash = {}

          str_errors = rand(1..5) % 2 == 1 ? "" : str_errors_template
          query_params = "#{record.main_string}\n#{str_errors}#{record.additional_string}"
          review = generate_review(query_params, arr_review_length)
          # puts review
          new_hash[:id_review] = record.id
          new_hash[:review_ru] = review
          new_hash[:characters] = review.length
          new_hash[:control] = record.attributes.except('main_string', 'gender',
                                                        'additional_string', 'id',
                                                        'created_at', 'updated_at')
                                     .values.map { |v| v.nil? ? 'nil' : v }.join("_")

          add_new_record_to_model('ReadyReviews', new_hash)
          i +=1
        end
      end
    end
    i
  end

  def add_new_record_to_model(model_name, merged_hash)
    attempts = 0
    model_class = model_name.constantize
    begin
      record = model_class.new(merged_hash)
      record.save!
    rescue ActiveRecord::RecordInvalid => e
      attempts += 1
      if attempts < 4
        sleep(attempts) # Delay to not overwhelm the DB
        retry
      else
        puts "Failed to save record after 3 attempts: #{e.message}"
      end
    end
  end

  def generate_review(query_params, arr_review_length)
    # topics = "Создай отзыв о шинах , используя следующие параметры: "
    topics = "Создай эмоциональный раскрепощенный отзыв о шинах от лица водителя со стажем вождения от 5 до 15 лет, используя следующие параметры: "
    topics += "\n"
    topics += query_params
    topics += "\n"
    topics += "Длина отзыва: от #{arr_review_length[0]} до #{arr_review_length[1]} слов"
    # puts " topics ======  #{topics}"
    topics += "\n"
    topics += "в результат выведи только сгенерированный отзыв на русском языке"
    topics += "\n"
    topics += "Хочу также обратить внимание на то, что:"
    topics += "\n"
    topics += "- если в параметрах есть слова '195/65R15','GreenTire', 'SuperDefender', то именно они и должны использоваться в отзыве для  размера, бренда или модели шины."
    topics += "\n"
    topics += "- если Сезонность указана как летняя, то в отзыве не нужно писать об управляемости или торможении шины в зимних условиях (снег, лед) "
    topics += "\n"
    topics += "- под управляемостью подразумеваются следующие свойства для  шины: Курсовая устойчивость, Маневренность, Плавность хода, Сцепление с дорогой, Разгон, Торможение, Устойчивость к заносам."
    topics += "\n"
    topics += "Все эти свойства нужно использовать в отзыве вместо слова 'управляемость'"
    topics += "\n"
    topics += "- избегай, пожалуйста, предложений, напоминающих рекламные слоганы, например такого как \"Шины BRAND - настоящий прорыв в мире автоаксессуаров!\" "
    topics += "\n"
    topics += "или вот такого: \"Шины SIZE - надежный выбор для летнего сезона!\" "
    topics += "\n"

    attempts = 0
    new_text = nil
    begin
      new_text = ContentWriter.new.write_seo_text(topics, 3500)
      new_text = new_text['choices'][0]['message']['content'].strip if new_text
    rescue => e
      attempts += 1
      if attempts < 3
        sleep(2) # Delay to not overwhelm the service
        retry
      else
        puts "Произошла ошибка при получении текста: #{e.message}"
      end
    end

    # очистить текст
    new_text = first_text_clearing(new_text) if new_text

    new_text
  end

  def first_text_clearing(txt)
    txt = txt.gsub(/["'“”]/, '')
    txt = txt.gsub('*', '')

    # замена фраз
    txt = txt.gsub('для любого климата', 'для любой погоды')
    txt = txt.gsub('модель MODEL', 'MODEL')
    txt = txt.gsub(/для летнего сезона/i, 'на лето')
    txt = txt.gsub(/с дорожными условиями/i, 'с дорогой')
    txt = txt.gsub(/на любом асфальте/i, 'везде')
    txt = txt.gsub(/мо(е|ё)м авто(|мобиле) JLT/i, 'моем JLT')
    txt = txt.gsub(/своего авто(|мобиля) JLT/i, 'своего JLT')
    txt = txt.gsub(/для авто(|мобиля) JLT/i, 'для JLT')

    # удаление фраз из текста
    phrases_to_remove = [
      "для ((беззаботных|летних|зимних) поездок|безопасной езды)(| на автомобиле)",
      "в любых путешествиях", "для вашего автомобилЯ", "для безопасного вождения(\s|)(на дороге|)",
      "для использования на авто(мобиле|) JLT",
      "во время (летнего|зимнего) сезона", "в (жаркое|холодное) время года",
      "для повседневного использования", "для безопасности на дороге",
      "для безопасности и комфорта(\s|)(вождения|поездки|езды|на дороге|)",
      "Для тех, кто ценит безопасность и комфорт на дороге,",
      "(((нейтра|отрицате|положите)льный)|)(\s|)Отзыв(\s|)(от|)(\s|)(женщин(ы|а)|мужчин(ы|а)|)(\s|)(:|)",
      "(женщина|мужчина)(\s|)(:|)"
    ]

    phrases_to_remove.each do |phrase|
      txt = txt.gsub(/#{phrase}/i, '')
    end

    # полное удаление предложения  из текста
    words_to_remove = ["дюйм", "Спасибо", "(\d{3}\/\d{2})|(R\d{2,3})"]
    words_to_remove.each do |word|
      txt = remove_sentence_with_word(txt, word)
    end

    txt

  end

  def remove_sentence_with_word(txt, word)
    # функция для удаления предложения содержащего слово [word]
    # В этом регулярном выражении (?<=^|\.|\?|\!)\s* является положительной lookbehind проверкой,
    # которая ищет начало строки или конец предыдущего предложения.
    # [^\.!?]*#{word}[^\.!?]*[\.!?] матчит любое предложение которое содержит указанное слово.
    txt.gsub(/(?<=^|\.|\?|\!)\s*([^\.!?]*#{word}[^\.!?]*[\.!?])/i, '')
  end

end