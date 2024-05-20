# app/services/service_review.rb

module ServiceReview

  def random_array_with_average(type_review, type_season)
    # результатом является массив с оценками для легковых шин!!!
    # type_review: 1 - положительный, 2 - нейтральный, 3 - отрицательный
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

  def topics_array
    arr = []

    sizes = ["SIZE", ""]
    brands = ["BRAND", ""]
    models = ["MODEL", ""]
    genders = ["мужчина", "женщина"]
    seasons = ["зимние", "летние", "всесезонные"]
    types_review = ["положительный", "негативный", "нейтральный"]

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
                  size: size,
                  brand: brand,
                  model: model,
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

  def generate_review
    topics = topics_array
    query_params = topics[1][:str]
    puts "Query params is: #{topics[1]}"

    review_length = case rand(1..10) % 3
                    when 1
                      "небольшой (больше 100 и не более 300 печатных символов)"
                    when 2
                      "короткий (не более 100 печатных символов)"
                    else
                      "большой (не менее 300 печатных символов)"
                    end
    puts "review_length = #{review_length}"

    topics = "Создай #{review_length} отзыв о шинах, используя следующие параметры: "
    # topics = "Создай короткий отзыв о шинах, используя следующие параметры: "
    topics += query_params
    topics += "\n"
    topics += "в результат выведи только сгенерированный отзыв на русском языке"

    new_text = ContentWriter.new.write_seo_text(topics, 3500) #['choices'][0]['message']['content'].strip

    if new_text
      begin
        new_text = new_text['choices'][0]['message']['content'].strip
      rescue => e
        puts "Произошла ошибка: #{e.message}"
      end
    end

    new_text
  end

end