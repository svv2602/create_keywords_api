# app/services/service_review.rb
require_relative '../../app/services/dictionaries/const_reviews'
module ServiceReview

  def random_array_with_average(type_review, type_season)
    # результатом является массив с оценками для легковых шин!!!
    # type_review: 1 - положительный, 2 - нейтральный, 3 - негативный
    # type_season: 1 - летние легковые шины, другое значение для остальных шин
    number_of_ratings = type_season == 1 ? 4 : 6
    n = values_for_review_type(type_review)
    array = []
    number_of_ratings.times do |i|
      num = (rand(n..10.0) * 2).round / 2.0
      el = i % 2 == 0 ? num : 2 * n - array[i - 1]
      if el <= 9 && el >= 2.5
        el += 0.5 * rand(1..10) % 2 == 0 ? -1 : 1 if rand(1..10) % 2 == 0
      end
      array[i] = el > 1 ? el : 1.0
    end
    # puts array.inspect
    array
  end

  def values_for_review_type(n)
    result = case n
             when 1
               rand(8..10)
             when 2
               rand(6..8)
             when 3
               rand(3..6)
             else
               10
             end

    result.to_f
  end

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
    genders = GENDERS
    seasons = SEASONS
    types_review = TYPES_REVIEW

    sizes.each do |size|
      brands.each do |brand|
        models.each do |model|
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
    Review.delete_all
    i = 0
    array_hash_topics = topics_array
    array_hash_topics.each do |hash_topic|
      season = hash_topic[:season]
      types_review = hash_topic[:type_review]
      arrays = array_additional_information_for_text_generation(season, types_review)
      arrays.each do |array|
        hash_additional_information = str_additional_information_for_text_generation(array)
        merged_hash = hash_topic.merge(hash_additional_information)
        add_new_record_to_review(merged_hash)
        i+=1
      end
    end
    return "Добавлено записей: #{i}"
  end

  def generating_texts_and_writing_to_tables
    str_errors_template = "Сделай в отзыве несколько грамматических ошибок в словах на кириллице так, как это мог бы сделать человек\n"
    i = 0
    j = 0
    array_hash_topics = topics_array
    array_hash_topics.each do |hash_topic|
      season = hash_topic[:season]
      types_review = hash_topic[:type_review]
      arrays = array_additional_information_for_text_generation(season, types_review)
      arrays.each do |array|
        hash_additional_information = str_additional_information_for_text_generation(array)
        merged_hash = hash_topic.merge(hash_additional_information)

        # puts "str ===\n #{query_params}\n"
        TEXT_LENGTH.each_with_index do |arr_review_length, index|
          count_repeat = TEXT_LENGTH.size - index
          count_repeat.times do
            str_errors = rand(1..5) % 2 == 1 ? "" : str_errors_template
            query_params = "#{merged_hash[:str]}\n#{str_errors}#{merged_hash[:additional_string]}\n"
            review = generate_review(query_params, arr_review_length)
            # puts review
            merged_hash[:review_ru] = review
            add_new_record_to_review(merged_hash)
          end

        end
        i += 1
        break if i == 3
      end
      i=0
      j += 1
      break if j == 1
    end
  end

  def add_new_record_to_review(merged_hash)
    attempts = 0
    begin
      record = Review.new(merged_hash)
      record.save!
    rescue ActiveRecord::RecordInvalid => e
      attempts += 1
      if attempts < 3
        sleep(0.5) # Delay to not overwhelm the DB
        retry
      else
        puts "Failed to save record after 3 attempts: #{e.message}"
      end
    end
  end

  def generate_review(query_params, arr_review_length)
    # review_length = case rand(1..10) % 3
    #                 when 1
    #                   "небольшой (больше 100 и не более 300 печатных символов)"
    #                 when 2
    #                   "короткий (не более 100 печатных символов)"
    #                 else
    #                   "большой (не менее 300 печатных символов)"
    #                 end
    #
    # topics = "Создай #{review_length} отзыв о шинах, используя следующие параметры: "
    #
    topics = "Создай отзыв о шинах (от #{arr_review_length[0]} до #{arr_review_length[1]} слов), используя следующие параметры: "
    topics += query_params
    topics += "\n"
    topics += "в результат выведи только сгенерированный отзыв на русском языке"
    topics += "\n"
    topics += "Хочу также обратить внимание на то, что:"
    topics += "\n"
    topics += "- если в параметрах есть слова '195/65R15','GreenTire', 'SuperDefender', то именно они и должны использоваться в отзыве для  размера, бренда или модели шины."
    topics += "\n"
    topics += "- если Сезонность указана как летняя, то в отзыве не нужно писать об управляемости или торможении шины в зимних условиях (снег, лед) "
    topics += "\n"
    topics += "- под управляемостью подразумеваются следующие свойства для  шины: Курсовая устойчивость, Маневренность, Плавность хода, Сцепление с дорогой, Разгон, Торможение, Устойчивость к заносам"
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
        sleep(0.5) # Delay to not overwhelm the service
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
    txt = txt.gsub('для любого климата', 'для любой погоды')
    txt = txt.gsub('модель MODEL', 'MODEL')
    txt = txt.gsub(/для летнего сезона/i, 'на лето')
    txt = txt.gsub(/с дорожными условиями/i, 'с дорогой')

    phrases_to_remove = ["для вашего автомобилЯ", "для беззаботных поездок на автомобиле", "в любых путешествиях",
                         "во время летнего сезона", "для летних поездок", "для безопасной езды", "в жаркое время года",
                         "для повседневного использования"]
    phrases_to_remove.each do |phrase|
      txt = txt.gsub(/#{phrase}/i, '')
    end

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