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
                str += "Сезонность: #{season}\n" unless season == ""
                str += "Размер шины: #{size}\n" unless size == ""
                str += "Бренд: #{brand}\n" unless brand == ""
                str += "Модель шины: #{model}\n" unless model == ""
                params = {
                  # size: size,
                  # brand: brand,
                  # model: model,
                  gender: gender,
                  season: season,
                  type_review: type_review,
                  str: str
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

  def generating_texts_and_writing_to_tables

    array_hash_topics = topics_array
    array_hash_topics.each do |hash_topic|
      season = hash_topic[:season]
      types_review = hash_topic[:type_review]
      arrays = array_additional_information_for_text_generation(season, types_review)
      arrays.each do |array|
        hash_additional_information = str_additional_information_for_text_generation(array)
        merged_hash = hash_topic.merge(hash_additional_information)

        query_params = "#{merged_hash[:str]}\n#{merged_hash[:additional_string]}\n"
        # puts "str ===\n #{query_params}\n"
        review = generate_review(query_params)
        # puts review

        merged_hash[:review_ru] = review
        add_new_record_to_review(merged_hash)

      end

    end

  end

  def add_new_record_to_review(merged_hash)
    merged_hash.delete(:str)
    merged_hash.delete(:additional_string)

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

  def generate_review(query_params)
    review_length = case rand(1..10) % 3
                    when 1
                      "небольшой (больше 100 и не более 300 печатных символов)"
                    when 2
                      "короткий (не более 100 печатных символов)"
                    else
                      "большой (не менее 300 печатных символов)"
                    end

    topics = "Создай #{review_length} отзыв о шинах, используя следующие параметры: "
    topics += query_params
    topics += "\n"
    topics += "в результат выведи только сгенерированный отзыв на русском языке"

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

    new_text
  end

end