# app/services/service_review_out.rb
require_relative '../../app/services/dictionaries/const_reviews'
require_relative '../../app/services/dictionaries/const_reviews_static'
require_relative '../../app/services/dictionaries/const_reviews_gender_male'
require_relative '../../app/services/dictionaries/const_reviews_gender_female'
require_relative '../../app/services/dictionaries/const_replace_for_reviews'
module ServiceReviewOut

  def makes_hash_for_collect_the_answer(tyres)
    new_hash = { tyres: [] }
    array_with_average = random_array_with_average(10,
                                                   tyres[:season],
                                                   tyres[:grade],
                                                   tyres[:number_of_reviews])
    puts "array_with_average = #{array_with_average.inspect}"
    array_with_average.each do |grade|
      size = tyres[:sizes_of_model].shuffle.first
      new_hash[:tyres] << {
        grade: grade,
        brand: tyres[:brand],
        model: tyres[:model],
        season: tyres[:season],
        width: size[:width],
        height: size[:height],
        diameter: size[:diameter],
        type_review: convert_rating_to_type(grade),
        id: size[:id]
      }
    end
    new_hash
  end

  def collect_the_answer(tyres, average = 0)
    # Используем новый алгоритм если включены feature flags
    if FeatureFlags.use_new_ai_model? || FeatureFlags.force_ai_processing?
      collect_the_answer_v2(tyres, average)
    else
      collect_the_answer_original(tyres, average)
    end
  end
  
  def collect_the_answer_original(tyres, average = 0)
    result = []
    array_reviews_id = []
    array_reviews_without_params_id = []
    tyres.each do |el|
      array_info = average == 0 ? create_hash_with_params(el) : el
      record = get_car_by_tire_size(array_info)
      tyres_size = "#{array_info[:width]}/#{array_info[:height]}R#{array_info[:diameter]}"
      season = array_info[:season]
      type_review = array_info[:type_review]

      array_average = average == 0 ? random_array_with_average(type_review, season) : random_array_with_average(type_review, season, array_info[:grade])

      control = value_field_control(season, type_review, array_average)
      # puts " control = value_field_control(season, type_review, array_average) ===== #{control}"
      if array_reviews_id.empty?
        random_review = ReadyReviews.order("RANDOM()").where(control: control).first
        # puts "random_review .empty"
      else
        random_review = ReadyReviews.order("RANDOM()").where(control: control).where.not(id: array_reviews_id).first
        # puts "random_review  not empty"
      end

      puts "array_reviews_id = #{array_reviews_id}"

      language = rand(1..10) % 2 == 0 ? "ru" : "ua"
      array_info[:language] = language
      array_info[:author] = ''

      # Новая логика распределения отзывов по типам
      random_percent = rand(1..100)
      
      if type_review == -1
        # Для негативных отзывов: 50% длинные, 35% средние, 15% короткие
        if random_percent <= 50 && random_review
          # 50% - длинные отзывы с параметрами
          array_reviews_id << random_review.id
          gender = Review.find_by(id: random_review[:id_review])[:gender]
          review = language == "ru" ? random_review[:review_ru] : random_review[:review_ua]
        elsif random_percent <= 85
          # 35% - средние отзывы с сезонностью
          control = control.split('_').take(2).join('_')
          random_review = ReadyReviewsWithoutParam.order("RANDOM()").where(control: control).where.not(id: array_reviews_without_params_id).first
          if random_review
            array_reviews_without_params_id << random_review&.id
            gender = random_review[:gender]
            review = language == "ru" ? random_review[:review_ru] : random_review[:review_ua]
          end
        else
          # 15% - короткие статические отзывы
          review = get_static_review(type_review, language)
        end
      else
        # Для положительных/нейтральных отзывов: 30% длинные, 55% средние, 15% короткие
        if random_percent <= 30 && random_review
          # 30% - длинные отзывы с параметрами
          array_reviews_id << random_review.id
          gender = Review.find_by(id: random_review[:id_review])[:gender]
          review = language == "ru" ? random_review[:review_ru] : random_review[:review_ua]
        elsif random_percent <= 85
          # 55% - средние отзывы с сезонностью
          control = control.split('_').take(2).join('_')
          random_review = ReadyReviewsWithoutParam.order("RANDOM()").where(control: control).where.not(id: array_reviews_without_params_id).first
          if random_review
            array_reviews_without_params_id << random_review&.id
            gender = random_review[:gender]
            review = language == "ru" ? random_review[:review_ru] : random_review[:review_ua]
          end
        else
          # 15% - короткие статические отзывы
          review = get_static_review(type_review, language)
        end
      end

      review ||= get_static_review(type_review, language) # если review равно nil или false

      review = make_changes_to_review_template(review,
                                               language,
                                               array_info[:brand],
                                               array_info[:model],
                                               array_info[:width],
                                               array_info[:height],
                                               array_info[:diameter],
                                               names_auto(record, language)[:auto_review])

      review = correct_text(review, language)
      
      # НОВАЯ УНИВЕРСАЛЬНАЯ ПОСТОБРАБОТКА ДЛЯ УНИКАЛЬНОСТИ
      if FeatureFlags.universal_postprocessing_enabled? && review && review.length > 5
        processor = UniversalReviewProcessor.new
        context = {
          brand: array_info[:brand],
          model: array_info[:model],
          car: names_auto(record, language)[:auto],
          language: language,
          type_review: type_review
        }
        
        processed_review = processor.process_for_uniqueness(review, context)
        review = processed_review if processed_review  # используем обработанный, если успешно
      end
      
      review = change_chars_register(review) if review
      
      # Умные или классические эмодзи
      if FeatureFlags.smart_emoji_enabled?
        emoji_manager = SmartEmojiManager.new
        emoji_context = { language: language, season: array_info[:season] }
        review = emoji_manager.add_contextual_emoji(review, type_review, emoji_context)
      else
        review = review ? review + add_emoji(type_review) : add_emoji(type_review)
      end

      array_info[:author] = get_author_name(language, gender)
      array_info[:review] = review
      array_info[:experience] = get_experience(review)
      array_info[:tyres_size] = tyres_size
      array_info[:names_auto] = names_auto(record, language)[:auto]

      if rand(1..100) % 10 == 0
        array_info[:array_average] = []
        array_info[:grade] = (array_average.sum.to_f / array_average.size * 2).round / 2.0
      else
        array_info[:array_average] = array_average
        array_info[:grade] = 0
      end

      result << array_info
    end
    result
  end

  def change_chars_register(text)
    n = rand(1..10)
    case n
    when 2, 3, 4, 5, 7, 9
      splitted_text = text.split(/(?<=[.!?])/)
      result = splitted_text.map { |sentence| sentence.strip.capitalize }.join(' ')
    when 1, 8
      result = text.downcase
      result =  result.gsub(/,|\./,"") if rand(1..100)%2 == 0
    else
      result = text.upcase
      result =  result.gsub(/,|\./,"") if rand(1..100)%3 == 0
    end
    result
  end

  def get_sample_brand(brand,language)
    brand_2 = ""
    arr_name_brand_2 = NAME_BRANDS_REVIEW.reject { |hash| hash.key?(brand) }
    brand_2_sample = arr_name_brand_2.sample
    brand_2_sample.each do |key, value|
      brand_2 = rand(1..100)%2==0? value[:en] : value[language.to_sym]
    end
    brand_2
  end

  def make_changes_to_review_template(text, language, brand, model, size_width, size_height, size_diameter, auto)
    result = text

    brand_2 = get_sample_brand(brand,language)
    puts "brand_2 = #{brand_2.inspect}"

    n = rand(1..10)
    case n
    when 1, 3, 5, 7, 9
      brand = brand.capitalize
      model = model.capitalize
      brand_2 = brand_2.capitalize
    when 2, 4, 8
      brand = brand.downcase
      model = model.downcase
      brand_2 = brand_2.downcase
    else
      brand = brand.upcase
      model = model.upcase
      brand_2 = brand_2.upcase
    end

    tyres_size = case rand(1..10)
                 when 1
                   "#{size_width}/#{size_height}R#{size_diameter}"
                 when 2
                   "#{size_width}/#{size_height} R#{size_diameter}"
                 when 3
                   "#{size_width} #{size_height} R#{size_diameter}"
                 when 4
                   "R#{size_diameter} на #{size_width}/#{size_height}"
                 when 5
                   "#{size_width}/#{size_height} #{size_diameter}"
                 when 6
                   "#{size_width} #{size_height} #{size_diameter}"
                 when 7
                   "#{size_width}/#{size_height} на #{size_diameter}"
                 else
                   "#{size_width}/#{size_height}R#{size_diameter}"
                 end

    if result
      result = result.gsub(/\b(GreenTire|ГринТа(е|й)р)_2\b/i, brand_2)
      result = result.gsub(/\bGreenTire|ГринТа(е|й)р\b/i, brand)
      result = result.gsub(/SuperDefender|супердефендер|суперdefender/i, model)
      result = result.gsub(/195\/65R15/i, tyres_size)
      result = result.gsub(/JLT|ЖЛТ/i, auto)
    end

    result

  end

  def correct_text(text, language)
    hash_delete_text_ru = HASH_DELETE_TEXT_RU
    hash_delete_text_ua = HASH_DELETE_TEXT_UA
    hash_replace_text_ru = HASH_REPLACE_TEXT_RU
    hash_replace_text_ua = HASH_REPLACE_TEXT_UA
    result = text

    if language == "ru"
      hash_delete_text = hash_delete_text_ru
      hash_replace_text = hash_replace_text_ru
    else
      hash_delete_text = hash_delete_text_ua
      hash_replace_text = hash_replace_text_ua
    end

    if result
      hash_delete_text.each do |key, value|
        value.each do |regex|
          result = result.gsub(regex, "") unless rand(1..100) % key == 0
        end
      end

      hash_replace_text.each do |key, value|
        result = result.gsub(key, value)
      end

      result = replace_synonyms_in_sentence(result, language)
    end



    result
  end



  def replace_synonyms_in_sentence(sentence, language)
    words = sentence.split(' ')
    replaced_words = words.map do |word|
      replace_synonym(word, language)
    end
    replaced_words.join(' ')
  end

  def replace_synonym(word, language)
    const_name = language == "ru" ? :ru : :ua
    SINONIMS[const_name].each do |arr|
      if arr.any? { |synonym| synonym == word }
        new_arr = arr.reject { |synonym| synonym == word }
        return new_arr.sample
      end
    end
    word
  end

  def convert_season_to_number(season)
    # Конвертация строкового значения сезона в числовое
    case season.to_s.downcase
    when 'summer', 'летние', '1'
      1
    when 'winter', 'зимние', '2'
      2
    when 'all_season', 'всесезонные', '3'
      3
    else
      season.to_i
    end
  end

  def create_hash_with_params(hash_params)
    array_info = {}
    array_sym = [:brand, :model, :width, :height, :diameter, :season, :type_review, :id]
    array_sym.each { |sym| array_info[sym] = hash_params[sym] }

    # Конвертируем сезон из строки в число, если нужно
    array_info[:season] = convert_season_to_number(array_info[:season]) if array_info[:season]

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

  def get_experience(text)
    # генерация стажа, если есть в тексте - берем из текста, иначе - случайное число
    matches = text.scan(/\b(?<=\s|^)(\d{1,2})\b/)
    experience = matches[0].nil? ? rand(3..20) : matches[0][0].to_i
    result = rand(1..100) % 3 == 0 ? "" : experience
    result

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
    # Добавляем ! в конец предложения, если там его нет
    if rand(1..10) % 2 == 0
      unless result.end_with?('.', '!', '?')
        result += "!"
      end
    end

    # добавить рекомендации
    if rand(1..100) % 3 == 0 && (static_reviews != STATIC_REVIEWS_NEUTRAL)
      result += " "
      result += language == "ru" ? static_reviews[:advices_ru]&.shuffle.first : static_reviews[:advices_ua]&.shuffle.first
      result += rand(1..100) % 10 == 0 ? "!!!" : "!"
    end

    result

  end

  def add_emoji(type_review)
    result = ''
    # добавить эмодзи
    if rand(1..100) % 4 == 0 && type_review != 0
      arr_emoji = type_review == 1 ? POSITIVE_EMOTION_EMOJI : NEGATIVE_EMOTION_EMOJI
      n = rand(1..100) % 5 == 0 ? rand(2..5) : rand(1..2)
      n.times do
        result += arr_emoji.sample
      end
    end
    separator = result.size > 2 && rand(1..100) % 2 == 0 ? "\n" : (rand(1..100) % 2 == 0 ? "" : " ")
    result = separator + result
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
      author += date_birthday if rand(1..10) % 5 == 0
      author.downcase! if rand(1..2) % 2 == 0
    elsif array3.include?(author)
      author += date_birthday if rand(1..10) % 4 == 0
      author.downcase! if rand(1..2) % 2 == 0
    elsif array4.include?(author)
      author += date_birthday if rand(1..10) % 3 == 0
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
    result += separator if rand(1..5) % 2 == 0 && separator == "_"
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

  def random_array_with_average(type_review, type_season, evaluation_for_array = 0, amount_of_elements = 0)
    # результатом является массив с оценками для легковых шин!!!
    # type_review: 1 - положительный, 2 - нейтральный, 3 - негативный, для evaluation_for_array <> 0 - любое
    # type_season: 1 - летние легковые шины, другое значение для остальных шин

    if amount_of_elements == 0
      number_of_ratings = type_season == 1 ? 4 : 6
    else
      number_of_ratings = amount_of_elements
    end

    n = evaluation_for_array == 0 ? values_for_review_type(type_review) : evaluation_for_array
    puts "n == #{n}"
    array = []
    number_of_ratings.times do |i|
      num = (rand(n..5.0) * 2).round / 2.0
      el = i % 2 == 0 ? num : 2 * n - array[i - 1]
      el = (el * 2).round / 2.0 # округление с точностью 0,5

      # внести в массив погрешность
      if el <= 4 && el >= 1
        el += 0.5 * rand(1..5) % 2 == 0 ? -1 : 1 if rand(1..5) % 2 == 0
      end

      array[i] = el > 1 ? el : 1.0
    end
    array.shuffle!
    # puts array.inspect
    array
  end

  def values_for_review_type(n)
    result = case n
             when 1
               rand(4.0..5.0)
             when 0
               rand(2.0...4.0)
             when -1
               rand(0...2.0)
             else
               5
             end

    result.to_f
  end

  def arr_values_for_review_type(arr)
    str = ''
    arr.each do |el|
      str += "_"
      str += convert_rating_to_type(el).to_s
    end

    str
  end

  def convert_rating_to_type(number)
    result = case number
             when 4.0..5.0
               1
             when 2.0...4.0
               0
             when 0...2.0
               -1
             else
               -1
             end
    result
  end

  def value_type_review(text)
    type_review = case text
                  when "положительный"
                    1
                  when "негативный"
                    -1
                  when "нейтральный"
                    0
                  end
    type_review
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
  
  # ==================== НОВЫЙ УЛУЧШЕННЫЙ АЛГОРИТМ ====================
  
  def collect_the_answer_v2(tyres, average = 0)
    result = []
    array_reviews_id = []
    array_reviews_without_params_id = []

    tyres.each do |el|
      array_info = average == 0 ? create_hash_with_params(el) : el
      record = get_car_by_tire_size(array_info)
      tyres_size = "#{array_info[:width]}/#{array_info[:height]}R#{array_info[:diameter]}"
      season = array_info[:season]
      type_review = array_info[:type_review]

      # НОВАЯ ЛОГИКА: Генерируем оценки и метаданные ДО обработки AI
      array_average = average == 0 ? random_array_with_average(type_review, season) : random_array_with_average(type_review, season, array_info[:grade])
      control = value_field_control(season, type_review, array_average)

      # Определяем язык
      language = rand(1..10) % 2 == 0 ? "ru" : "ua"
      array_info[:language] = language

      # ВАЖНО: Генерируем пол и имя ДО AI-обработки
      gender = ["мужчина", "женщина"].sample
      array_info[:gender] = gender
      array_info[:author] = get_author_name(language, gender)

      # ВАЖНО: Вычисляем итоговую оценку ДО AI-обработки
      if rand(1..100) % 10 == 0
        array_info[:array_average] = []
        array_info[:grade] = (array_average.sum.to_f / array_average.size * 2).round / 2.0
      else
        array_info[:array_average] = array_average
        array_info[:grade] = (array_average.sum.to_f / array_average.size * 2).round / 2.0
      end

      # ЭТАП 1: Получение базового отзыва (как раньше)
      review = select_review_source_v2(control, type_review, array_reviews_id, array_reviews_without_params_id)

      # ЭТАП 2: Определение стратегии обработки
      processing_strategy = determine_processing_strategy(review, type_review, array_info)

      # ЭТАП 3: Обработка отзыва с учетом пола и оценок
      case processing_strategy
      when :ai_enhanced
        review = process_with_full_ai_pipeline(review, array_info, record, language)
      when :hybrid
        review = process_with_hybrid_approach(review, array_info, record, language)
      else
        review = process_with_classic_method(review, array_info, record, language)
      end

      # ЭТАП 4: Финальная сборка результата
      array_info[:review] = review
      array_info[:experience] = get_experience(review)
      array_info[:tyres_size] = tyres_size
      array_info[:names_auto] = names_auto(record, language)[:auto]

      result << array_info
    end
    result
  end
  
  private
  
  def select_review_source_v2(control, type_review, array_reviews_id, array_reviews_without_params_id)
    # Логика выбора источника отзыва (из существующего алгоритма)
    if array_reviews_id.empty?
      random_review = ReadyReviews.order("RANDOM()").where(control: control).first
    else
      random_review = ReadyReviews.order("RANDOM()").where(control: control).where.not(id: array_reviews_id).first
    end

    # вероятность развернутого отзыва
    n = type_review == -1 ? 2 : 5
    language = rand(1..10) % 2 == 0 ? "ru" : "ua"

    if random_review && rand(1..100) % n == 0
      # подбор отзыва с учетом параметров
      array_reviews_id << random_review.id
      review = language == "ru" ? random_review[:review_ru] : random_review[:review_ua]

    elsif rand(1..100) % 4 == 0
      # подбор отзыва с сезонностью без учета параметров
      control = control.split('_').take(2).join('_')
      random_review = ReadyReviewsWithoutParam.order("RANDOM()").where(control: control).where.not(id: array_reviews_without_params_id).first
      if random_review
        array_reviews_without_params_id << random_review&.id
        review = language == "ru" ? random_review[:review_ru] : random_review[:review_ua]
      end

    else
      # подбор короткого отзыва без сезонности и параметров
      review = get_static_review(type_review, language)
    end

    review || get_static_review(type_review, language)
  end
  
  def determine_processing_strategy(review, type_review, array_info)
    # Решаем какой метод обработки использовать
    return :ai_enhanced if FeatureFlags.force_ai_processing?
    return :classic if review.to_s.length < 30  # короткие отзывы обрабатываем по-старому
    return :ai_enhanced if type_review == -1 && review.to_s.length > 100  # сложные негативные
    return :hybrid if FeatureFlags.hybrid_processing_enabled?
    
    :classic  # по умолчанию старый алгоритм
  end
  
  def process_with_full_ai_pipeline(review, array_info, record, language)
    return review if review.blank?
    
    # 1. Базовая подстановка (как в оригинале)
    review = make_changes_to_review_template(review,
                                           language,
                                           array_info[:brand],
                                           array_info[:model],
                                           array_info[:width],
                                           array_info[:height],
                                           array_info[:diameter],
                                           names_auto(record, language)[:auto_review])
    
    # 2. AI-улучшение естественности  
    if review.length > 20
      naturalizer = TextNaturalizer.new
      context = build_full_context(array_info, record, language)
      review = naturalizer.naturalize_review(review, context)
    end
    
    # 3. Умный контроль длины
    if FeatureFlags.length_control_enabled? && review.length > 10
      target_length = TextLengthManager.determine_target_length(array_info[:type_review], review)
      length_manager = TextLengthManager.new(target_length)
      context = build_length_context(array_info, record, language)
      review = length_manager.adjust_text_length(review, context)
    end
    
    # 4. Интеллектуальная обработка регистра
    review = smart_case_adjustment(review, language) if review
    
    # 5. Контекстные эмодзи
    if FeatureFlags.smart_emoji_enabled?
      emoji_manager = SmartEmojiManager.new
      emoji_context = {
        language: language,
        season: array_info[:season],
        type_review: array_info[:type_review]
      }
      review = emoji_manager.add_contextual_emoji(review, array_info[:type_review], emoji_context)
    else
      review = review ? review + add_emoji(array_info[:type_review]) : add_emoji(array_info[:type_review])
    end
    
    review
  end
  
  def process_with_hybrid_approach(review, array_info, record, language)
    return review if review.blank?
    
    # Старая логика для базовой обработки
    review = make_changes_to_review_template(review,
                                           language,
                                           array_info[:brand],
                                           array_info[:model],
                                           array_info[:width],
                                           array_info[:height],
                                           array_info[:diameter],
                                           names_auto(record, language)[:auto_review])
    
    review = correct_text(review, language)
    
    # Новая логика только для проблемных случаев
    if needs_ai_improvement?(review)
      naturalizer = TextNaturalizer.new
      context = build_basic_context(array_info, record, language)
      review = naturalizer.improve_problematic_parts(review, context)
    end
    
    # Классическая финализация
    review = change_chars_register(review) if review
    
    # Умные или классические эмодзи
    if FeatureFlags.smart_emoji_enabled?
      emoji_manager = SmartEmojiManager.new
      emoji_context = { language: language, season: array_info[:season] }
      review = emoji_manager.add_contextual_emoji(review, array_info[:type_review], emoji_context)
    else
      review = review ? review + add_emoji(array_info[:type_review]) : add_emoji(array_info[:type_review])
    end
    
    review
  end
  
  def process_with_classic_method(review, array_info, record, language)
    # Существующий алгоритм без изменений
    return review if review.blank?
    
    review = make_changes_to_review_template(review,
                                           language,
                                           array_info[:brand],
                                           array_info[:model],
                                           array_info[:width],
                                           array_info[:height],
                                           array_info[:diameter],
                                           names_auto(record, language)[:auto_review])

    review = correct_text(review, language)
    review = change_chars_register(review) if review
    review = review ? review + add_emoji(array_info[:type_review]) : add_emoji(array_info[:type_review])
    
    review
  end
  
  def build_full_context(array_info, record, language)
    {
      brand: array_info[:brand],
      model: array_info[:model],
      car: names_auto(record, language)[:auto],
      type_review: array_info[:type_review],
      season: array_info[:season],
      language: language,
      width: array_info[:width],
      height: array_info[:height],
      diameter: array_info[:diameter],
      # НОВЫЕ ПАРАМЕТРЫ: пол и оценки
      gender: array_info[:gender],  # "мужчина" или "женщина"
      grade: array_info[:grade],  # Итоговая оценка (1-5)
      array_average: array_info[:array_average]  # Массив оценок по характеристикам
    }
  end
  
  def build_basic_context(array_info, record, language)
    {
      brand: array_info[:brand],
      model: array_info[:model],
      type_review: array_info[:type_review],
      language: language
    }
  end
  
  def build_length_context(array_info, record, language)
    {
      brand: array_info[:brand],
      model: array_info[:model],
      car: names_auto(record, language)[:auto],
      type_review: array_info[:type_review],
      season: array_info[:season]
    }
  end
  
  def needs_ai_improvement?(review)
    return false if review.blank? || review.length < 30
    
    # Проверяем наличие проблемных паттернов
    problematic_patterns = [
      /данные шины/i,
      /представленная модель/i,
      /рассматриваемый продукт/i,
      /в заключение/i,
      /подводя итог/i
    ]
    
    problematic_patterns.any? { |pattern| review.match?(pattern) }
  end
  
  def smart_case_adjustment(review, language)
    return review if review.blank?
    
    # Более умная обработка регистра с учетом контекста
    sentences = review.split(/[.!?]+/).reject(&:empty?)
    
    adjusted_sentences = sentences.map.with_index do |sentence, index|
      sentence = sentence.strip
      
      # Первое предложение всегда с заглавной буквы
      if index == 0
        sentence.capitalize
      else
        # Остальные с вероятностью
        case rand(10)
        when 1, 2  # 20% - все строчные
          sentence.downcase
        when 9     # 10% - все заглавные (для эмоций)
          sentence.upcase
        else       # 70% - нормальный регистр
          sentence.capitalize
        end
      end
    end
    
    result = adjusted_sentences.join('. ').strip
    result += '.' unless result.end_with?('.', '!', '?')
    result
  end
  
  def get_gender_from_review(review)
    # Пытаемся определить пол из отзыва или возвращаем случайный
    review_text = review.to_s
    return "женщина" if review_text.match?(/(довольна|рада|счастлива)/i)
    return "мужчина" if review_text.match?(/(доволен|рад|счастлив)/i)
    
    # По умолчанию случайно
    ["мужчина", "женщина"].sample
  end

end


