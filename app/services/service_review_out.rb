# app/services/service_review_out.rb
require_relative '../../app/services/dictionaries/const_reviews'
require_relative '../../app/services/dictionaries/const_reviews_static'
module ServiceReviewOut

  def collect_the_answer(tyres)
    result = []
    tyres.each do |el|
      array_info = create_hash_with_params(el)
      puts "array_info === #{array_info.inspect}"
      record = get_car_by_tire_size(array_info)
      puts "record === #{record.inspect}"
      tyres_size = "#{array_info[:width]}/#{array_info[:height]}R#{array_info[:diameter]}"
      season = array_info[:season]
      type_review = array_info[:type_review]

      array_average = random_array_with_average(type_review, season)
      control = value_field_control(season, type_review, array_average)

      random_review = ReadyReviews.where("control = ?", control).order("RANDOM()").first
      language = rand(1..10) % 2 == 0 ? "ru" : "ua"

      # ===================================
      # тест - удалить
      language = "ru"
      # ===================================

      array_info[:language] = language
      array_info[:author] = ''

      if random_review
        gender = Review.find_by(id: random_review[:id_review])[:gender]
        array_info[:author] = get_author_name(language, gender)
        review = language == "ru" ? random_review[:review_ru] : random_review[:review_ua]

        array_info[:review] = make_changes_to_review_template(review, array_info[:brand],
                                                              array_info[:model],
                                                              array_info[:width],
                                                              array_info[:height],
                                                              array_info[:diameter],
                                                              names_auto(record, language)[:auto_review])
      else
        array_info[:review] = get_static_review(type_review, language)
        array_info[:author] = get_author_name(language)
      end

      array_info[:tyres_size] = tyres_size
      array_info[:names_auto] = names_auto(record, language)[:auto]
      array_info[:array_average] = array_average
      array_info[:control] = control

      result << array_info
      puts "tyres === #{result}"

    end
    result
  end

  def make_changes_to_review_template(text, brand, model, size_width, size_height, size_diameter, auto)
    result = text
    n = rand(1..10)
    case n
    when 1, 3, 5, 7, 9
      brand = brand.capitalize
      model = model.capitalize
    when 2, 4, 8
      brand = brand.downcase
      model = model.downcase
    else
      brand = brand.upcase
      model = model.upcase
    end

    tyres_size = "#{size_width}/#{size_height}R#{size_diameter}"
    result = result.gsub(/GreenTire/i, brand)
    result = result.gsub(/SuperDefender/i, model)
    result = result.gsub(/супердефендер/i, model)
    result = result.gsub(/195\/65R15/i, tyres_size)
    result = result.gsub(/JLT/i, auto)
    result
  end

  def create_hash_with_params(hash_params)
    array_info = {}
    array_sym = [:brand, :model, :width, :height, :diameter, :season, :type_review]
    array_sym.each { |sym| array_info[sym] = hash_params[sym] }
    array_info
  end

  def get_car_by_tire_size(hash_params)
    # случайный автомобиль
    record_with_car = TestTableCar2KitTyreSize.where(width: "#{hash_params[:width]}.00",
                                                     height: "#{hash_params[:height]}.00",
                                                     diameter: "#{hash_params[:diameter]}.00")
                                              .order('RANDOM()')
                                              .first
    record_with_car
  end

  def get_static_review(type_review, language = "ru")
    static_reviews = case type_review
                     when 1
                       STATIC_REVIEWS_POSITIVE
                     when -1
                       STATIC_REVIEWS_NEGATIVE
                     when 0
                       STATIC_REVIEWS_NEUTRAL
                     end
    result = language == "ru" ? static_reviews[:reviews_ru].shuffle.first : static_reviews[:reviews_ua].shuffle.first
    result
  end

  def get_author_name(language, gender = "мужчина")

    hash_names = gender == "мужчина" ? MALE_NAMES : FEMALE_NAMES
    hash_patronymics = gender == "мужчина" ? MALE_PATRNYMICS : FEMALE_PATRNYMICS
    array_patronymics = hash_patronymics["patronymics_#{language}".to_sym]

    array1 = hash_names["names_#{language}".to_sym]
    array2 = hash_names["diminutive_names_#{language}".to_sym]
    array3 = hash_names[:names_en]
    array4 = hash_names[:diminutive_names_en]

    array_names = array1 + array2 + array3 + array4
    author = array_names.shuffle.first

    if array1.include?(author)
      author += " " + array_patronymics.shuffle.first if rand(1..5) % 4 == 0
    elsif array2.include?(author)
      author += date_birthday if rand(1..5) % 4 == 0
      author.downcase! if rand(1..2) % 2 == 0
    elsif array3.include?(author)
      author += date_birthday if rand(1..5) % 4 == 0
      author.downcase! if rand(1..2) % 2 == 0
    elsif array4.include?(author)
      author += date_birthday if rand(1..2) % 2 == 0
      author.downcase! if rand(1..2) % 2 == 0
    end

    author
  end

  def date_birthday
    result = ''
    mm = normal_value(rand(1..12))
    dd = normal_value(rand(1..28))
    separator = case rand(1..10)
                when 1
                  ""
                when 2, 8
                  "_"
                when 3
                  "-"
                else
                  ""
                end
    result += separator if rand(1..5) % 2 == 0
    result += rand(1..5) % 2 == 0 ? rand(100..10000).to_s : dd + separator + mm
    result
  end

  def normal_value(n)
    result = n < 10 ? "0" + n.to_s : n.to_s
    result
  end

  def names_auto(record, language)
    result = {}
    # выбор поля по языку
    field = rand(1..5) % 2 == 1 ? "name" : "translit_#{language}"

    auto_brand = record.kit.model.brand.send(field)
    auto_model = record.kit.model.send(field)

    # добавить год
    str_year = rand(1..2) % 2 == 1 ? " г." : ""
    auto_year = rand(1..2) % 2 == 1 ? record.kit.year + str_year : ""

    # добавить двигатель
    motor = rand(1..6) % 3 == 1 ? record.kit.name.split(' ')[0] + " " : ""

    # бренд и модель для отзыва (body)
    auto_brand_review = rand(1..5) % 2 == 1 ? record.kit.model.brand.name : auto_brand

    if auto_model
      auto_model_review = rand(1..5) % 2 == 1 ? record.kit.model.name : auto_model
    else
      auto_model_review = record.kit.model.name
    end
    auto_review = case rand(1..3)
                  when 1
                    "#{auto_brand_review} #{auto_model_review} "
                  when 2
                    "#{auto_brand_review}"
                  else
                    "#{auto_model_review}"
                  end

    # авто для заголовка и тела отзыва
    result[:auto] = "#{auto_brand} #{auto_model} #{motor}#{auto_year} "
    result[:auto_review] = auto_review
    result

  end

  def random_array_with_average(type_review, type_season, evaluation_for_array = 0)
    # результатом является массив с оценками для легковых шин!!!
    # type_review: 1 - положительный, 2 - нейтральный, 3 - негативный
    # type_season: 1 - летние легковые шины, другое значение для остальных шин
    number_of_ratings = type_season == 1 ? 4 : 6
    n = evaluation_for_array == 0 ? values_for_review_type(type_review) : values
    array = []
    number_of_ratings.times do |i|
      num = (rand(n..10.0) * 2).round / 2.0
      el = i % 2 == 0 ? num : 2 * n - array[i - 1]
      if el <= 9 && el >= 2.5
        el += 0.5 * rand(1..10) % 2 == 0 ? -1 : 1 if rand(1..10) % 2 == 0
      end
      array[i] = el > 1 ? el : 1.0
    end
    array.shuffle!
    puts array.inspect
    array
  end

  def values_for_review_type(n)
    result = case n
             when 1
               rand(8..10)
             when 0
               rand(6..8)
             when -1
               rand(3..6)
             else
               10
             end

    result.to_f
  end

  def arr_values_for_review_type(arr)
    str = ''
    arr.each do |el|
      str += "_"
      str += case el
             when 7..10
               1
             when 5..8
               0
             when 0..5
               -1
             else
               -1
             end.to_s

    end

    str
  end

  def value_field_control(season_param, type_review_param, arr_values)
    # летние_положительный_1_1_1_1_nil_nil
    season = case season_param
             when 1
               "летние"
             when 2
               "зимние"
             when 3
               "всесезонные"
             end

    type_review = case type_review_param
                  when 1
                    "положительный"
                  when -1
                    "негативный"
                  when 0
                    "нейтральный"
                  end

    rating_string = arr_values_for_review_type(arr_values)

    str_nil = "_nil_nil"

    result = season + "_" + type_review + rating_string
    result += str_nil if season_param == 1
    result

  end

end


