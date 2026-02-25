# app/services/universal_review_processor.rb

class UniversalReviewProcessor
  def initialize
    @content_writer = ContentWriter.new
  end
  
  def process_for_uniqueness(original_review, context = {})
    return original_review if original_review.blank?

    # Анализируем оригинальный отзыв
    analysis = analyze_original_review(original_review)

    # Создаем умный промпт с учетом анализа
    prompt = build_smart_prompt(original_review, analysis, context)

    # Обрабатываем через AI
    processed_review = process_through_ai(prompt, analysis[:estimated_tokens])

    # Финальная обработка с проверкой длины
    final_review = finalize_review(processed_review, analysis, context)

    # НОВОЕ: Проверка и переписывание если длина превышена
    final_review = check_and_shorten_if_needed(final_review, context)

    final_review
  end
  
  private
  
  def analyze_original_review(text)
    words = text.split(/\s+/)
    sentences = text.split(/[.!?]+/).reject(&:empty?)
    
    {
      word_count: words.length,
      sentence_count: sentences.length,
      estimated_tokens: (text.length / 4.0).round, # примерно для русского
      style: determine_style(text),
      tone: determine_tone(text),
      has_emoji: text.match?(/[😀-🙏🚀-🛿]/u),
      has_caps: text.match?(/[А-ЯЁ]{3,}/),
      has_exclamation: text.include?('!'),
      length_category: categorize_length(words.length)
    }
  end
  
  def determine_style(text)
    return :very_short if text.split(/\s+/).length <= 3
    return :laconic if text.split(/\s+/).length <= 10
    return :casual if text.match?(/\b(круто|супер|класс|норм|ок)\b/i)
    return :detailed if text.length > 200
    return :formal if text.match?(/\b(рекомендую|советую|считаю)\b/i)
    :standard
  end
  
  def determine_tone(text)
    positive_words = text.scan(/\b(отлично|супер|класс|здорово|хорошо|прекрасно)\b/i).length
    negative_words = text.scan(/\b(плохо|ужасно|кошмар|разочарован|жалею)\b/i).length
    
    return :very_positive if positive_words > negative_words + 1
    return :very_negative if negative_words > positive_words + 1
    return :positive if positive_words > negative_words
    return :negative if negative_words > positive_words
    :neutral
  end
  
  def categorize_length(word_count)
    case word_count
    when 0..3
      :very_short
    when 4..10
      :short
    when 11..25
      :medium
    when 26..50
      :long
    else
      :very_long
    end
  end
  
  def build_smart_prompt(original_text, analysis, context)
    base_prompt = build_base_rewrite_prompt(original_text, analysis)
    base_prompt += build_context_instructions(context)
    base_prompt += build_style_preservation_instructions(analysis)
    base_prompt += build_length_instructions(analysis)
    base_prompt += build_final_instructions(analysis)
    
    base_prompt
  end
  
  def build_base_rewrite_prompt(original_text, analysis)
    <<~PROMPT
      Перепиши следующий отзыв о шинах, сделав его уникальным, но сохранив основной смысл и стиль:

      ОРИГИНАЛЬНЫЙ ОТЗЫВ: "#{original_text}"

      Требования к переписыванию:
    PROMPT
  end
  
  def build_context_instructions(context)
    instructions = ""

    # Обработка языка - ВАЖНО добавить в начало
    if context[:language] == 'ua'
      instructions += "- КРИТИЧНО ВАЖНО: Пиши відгук ТІЛЬКИ українською мовою!\n"
      instructions += "- Використовуй українські слова: 'шини', 'гальмування', 'зчеплення', 'керованість', 'знос'\n"
    else
      instructions += "- Пиши отзыв на русском языке\n"
    end

    if context[:brand]
      instructions += "- Обязательно используй бренд #{context[:brand]} в отзыве\n"
    end

    if context[:model]
      # Случайно выбираем формат названия модели (для разнообразия)
      if rand(100) < 40
        instructions += "- Обязательно упомяни модель #{context[:model]} в отзыве, используя ТРАНСЛИТЕРАЦИЮ на русском/украинском (например: Pilot Sport → Пайлот Спорт)\n"
      else
        instructions += "- Обязательно упомяни модель #{context[:model]} в отзыве (оригинальное латинское название)\n"
      end
    end

    if context[:car] && rand(100) < 30
      instructions += "- ОБЯЗАТЕЛЬНО упомяни автомобиль #{context[:car]} в отзыве\n"
      instructions += "- НЕ используй притяжательные местоимения (мой, свой) при упоминании авто\n"
    else
      # Если авто не указан или не выпал шанс - требуем упомянуть опыт эксплуатации
      instructions += "- НЕ упоминай конкретный автомобиль в отзыве\n"
      instructions += "- ОБЯЗАТЕЛЬНО упомяни сколько сезонов/километров на этих шинах (например: 'второй сезон', 'уже 15 тысяч накатал')\n"
    end

    # НОВОЕ: Инструкции по полу автора
    if context[:gender]
      if context[:gender] == "женщина"
        instructions += "- ВАЖНО: Пиши от лица женщины, используй женский род (купила, поставила, довольна, рада, рекомендую)\n"
      else
        instructions += "- ВАЖНО: Пиши от лица мужчины, используй мужской род (купил, поставил, доволен, рад, рекомендую)\n"
      end
    end

    # НОВОЕ: Инструкции по оценкам
    if context[:grade] && context[:grade] > 0
      instructions += build_grade_instructions(context[:grade], context[:array_average])
    end

    # Добавляем акцент на основе оценок свойств
    if context[:ratings_array]
      accent = select_accent_from_ratings(context[:ratings_array], context[:grade])
      if accent
        instructions += "- ГЛАВНЫЙ АКЦЕНТ ОТЗЫВА (сфокусируйся на этом): \"#{accent}\"\n"
        instructions += "- Не пытайся упомянуть все характеристики - сконцентрируйся на главном акценте\n"
      end
    end

    # Для негативных отзывов - требуем конкретику
    if context[:grade] && context[:grade] < 3.0
      instructions += "- Укажи КОНКРЕТНУЮ проблему (грыжа, быстрый износ, шум, плохая балансировка), а не просто 'плохие шины'\n"
    end

    # НОВОЕ: Инструкции по датам и времени покупки
    if context[:time_description]
      instructions += build_date_instructions(context)
    end

    # ВАЖНО: Запрет российских топонимов (prokoleso.ua - украинский интернет-магазин)
    instructions += build_geographic_restrictions

    instructions
  end

  # Выбирает акцент на основе массива оценок для переписывания отзывов
  def select_accent_from_ratings(ratings_array, grade = nil)
    return nil unless defined?(REVIEW_ACCENTS) && ratings_array.is_a?(Array)

    # Определяем тип отзыва по итоговой оценке
    is_negative = grade && grade < 3.0

    # Собираем подходящие оценки (позитивные для хороших отзывов, негативные для плохих)
    suitable_properties = []
    ratings_array.each_with_index do |rating, index|
      next if rating == 0
      next if index >= REVIEW_ACCENTS.keys.max + 1 # Защита от выхода за границы

      # Для негативного отзыва берем негативные оценки, для позитивного - позитивные
      if is_negative
        suitable_properties << { index: index, rating: rating } if rating == -1
      else
        suitable_properties << { index: index, rating: rating } if rating == 1
      end
    end

    # Если нет подходящих, берем любую ненулевую
    if suitable_properties.empty?
      ratings_array.each_with_index do |rating, index|
        next if rating == 0
        suitable_properties << { index: index, rating: rating }
      end
    end

    return nil if suitable_properties.empty?

    # Выбираем случайную
    selected = suitable_properties.sample
    property_accents = REVIEW_ACCENTS.dig(selected[:index], selected[:rating])
    return nil unless property_accents&.any?

    property_accents.sample
  end
  
  def build_style_preservation_instructions(analysis)
    instructions = ""
    
    case analysis[:style]
    when :very_short
      instructions += "- ОЧЕНЬ ВАЖНО: Оригинал крайне лаконичный - твой вариант должен быть тоже очень коротким (1-3 слова максимум)\n"
    when :laconic
      instructions += "- ВАЖНО: Оригинал лаконичный - сохрани краткость (до 10 слов максимум)\n"
    when :casual
      instructions += "- Сохрани разговорный неформальный стиль\n"
    when :detailed
      instructions += "- Сохрани подробность и развернутость изложения\n"
    when :formal
      instructions += "- Сохрани формальный стиль изложения\n"
    end
    
    case analysis[:tone]
    when :very_positive
      instructions += "- Сохрани очень позитивную эмоциональную окраску\n"
    when :very_negative
      instructions += "- Сохрани негативную критическую тональность\n"
    when :positive
      instructions += "- Сохрани позитивный настрой\n"
    when :negative
      instructions += "- Сохрани критический тон\n"
    when :neutral
      instructions += "- Сохрани нейтральную сдержанную тональность\n"
    end
    
    instructions
  end
  
  def build_length_instructions(analysis)
    instructions = ""
    
    case analysis[:length_category]
    when :very_short
      instructions += "- КРИТИЧЕСКИ ВАЖНО: Результат должен быть ОЧЕНЬ коротким (1-3 слова). Не расширяй!\n"
    when :short
      instructions += "- ВАЖНО: Результат должен быть коротким (4-10 слов). Не делай длиннее!\n"
    when :medium
      instructions += "- Длина: средняя (10-25 слов), можешь немного варьировать в этих пределах\n"
    when :long
      instructions += "- Сохрани развернутость (25-50 слов), можешь немного сократить или расширить\n"
    when :very_long
      instructions += "- Сохрани подробность изложения (50+ слов), детализация важна\n"
    end
    
    instructions += "- Количество предложений: примерно #{analysis[:sentence_count]} (плюс-минус 1)\n"
    
    instructions
  end
  
  def build_final_instructions(analysis)
    instructions = ""
    
    # CAPS запрещён — регистр управляется кодом постобработки
    instructions += "- ЗАПРЕЩЕНО писать ЗАГЛАВНЫМИ БУКВАМИ (CAPS LOCK). Пиши обычным регистром.\n"
    
    if analysis[:has_exclamation]
      instructions += "- Сохрани эмоциональность с восклицательными знаками\n"
    end
    
    instructions += "- НЕ добавляй эмодзи в текст (они добавятся отдельно)\n"
    instructions += "- Пиши от первого лица как реальный пользователь\n"
    instructions += "- Избегай рекламных клише и шаблонных фраз\n"
    instructions += "- Результат должен звучать естественно и по-человечески\n"
    instructions += "- КРИТИЧЕСКИ ВАЖНО: Максимальная длина отзыва - 1000 символов! Не превышай этот лимит!\n"
    instructions += "- ЗАПРЕЩЕНО использовать обращения к читателю: 'Друзі', 'Хлопці', 'Люди', 'Народ', 'Братья', 'Друзья', 'Ребята' и т.д.\n"
    instructions += "- ВАЖНО: Каждое предложение ДОЛЖНО быть завершено. Не обрывай текст на полуслове.\n"
    instructions += "- ЗАПРЕЩЕНО использовать иероглифы, символы китайского, японского, корейского и других восточноазиатских языков. Используй ТОЛЬКО кириллицу и латиницу!\n"
    instructions += "\nВерни ТОЛЬКО переписанный отзыв без дополнительных комментариев."

    instructions
  end
  
  def process_through_ai(prompt, estimated_tokens)
    max_tokens = [estimated_tokens * 2, 2000].max  # минимум 2000 токенов (Gemini thinking тратит ~8000-10000 из бюджета)
    
    attempts = 0
    begin
      response = @content_writer.generate_review(prompt, max_tokens, model_type: :review_generation)
      
      if response && response['choices'] && response['choices'][0]
        processed_text = response['choices'][0]['message']['content'].strip
        return clean_ai_response(processed_text)
      end
      
    rescue => e
      attempts += 1
      if attempts < 2
        Rails.logger.warn "AI processing failed, retrying: #{e.message}"
        sleep(1)
        retry
      else
        Rails.logger.error "AI processing failed after retries: #{e.message}"
        return nil  # вернем nil, чтобы использовать оригинал
      end
    end
    
    nil
  end
  
  def clean_ai_response(text)
    return nil if text.blank?

    # Удаляем иероглифы и символы восточноазиатских языков
    text = remove_asian_characters(text)

    # Заменяем стоп-слова на нормальные фразы
    text = replace_stop_words(text)

    # Убираем лишние кавычки и обрамления
    text = text.gsub(/^["«]|["»]$/, '')

    # Убираем префиксы типа "Отзыв:", "Переписанный отзыв:" и т.д.
    text = text.gsub(/^(отзыв|переписанный отзыв|результат):\s*/i, '')

    # Убираем эмодзи (они добавятся отдельно)
    text = text.gsub(/[😀-🙏🚀-🛿]/u, '')

    # Очищаем лишние пробелы
    text = text.gsub(/\s+/, ' ').strip

    return nil if text.blank?

    # Защита от обрезанного AI-ответа: если текст не заканчивается на знак препинания,
    # обрезаем до последнего полного предложения
    text = trim_to_last_complete_sentence(text)

    return nil if text.blank?
    text
  end

  def trim_to_last_complete_sentence(text)
    return text if text.blank?
    return text if text.match?(/[.!?]\s*$/)

    # Ищем последний знак конца предложения
    last_end = [text.rindex('.'), text.rindex('!'), text.rindex('?')].compact.max
    return text if last_end.nil? || last_end < 10

    text[0..last_end].strip
  end
  
  def finalize_review(processed_review, analysis, context)
    # Если AI обработка не удалась, возвращаем оригинал
    return nil if processed_review.blank?
    
    # Проверяем, что длина в разумных пределах
    processed_words = processed_review.split(/\s+/).length
    original_words = analysis[:word_count]
    
    # Если AI сильно изменил длину для коротких отзывов - отклоняем
    if analysis[:length_category] == :very_short && processed_words > 5
      Rails.logger.warn "AI made very short review too long: #{processed_words} words"
      return nil
    end
    
    if analysis[:length_category] == :short && processed_words > original_words * 2
      Rails.logger.warn "AI made short review too long: #{processed_words} vs #{original_words} words"
      return nil
    end
    
    processed_review
  end

  def build_grade_instructions(grade, array_average)
    instructions = ""

    # Интерпретируем итоговую оценку
    grade_interpretation = case grade
    when 4.5..5.0
      "восторженный, крайне позитивный"
    when 4.0...4.5
      "очень положительный, с большим энтузиазмом"
    when 3.5...4.0
      "положительный, доволен покупкой"
    when 3.0...3.5
      "в целом нейтральный, со средними впечатлениями"
    when 2.5...3.0
      "скорее нейтральный с легкими замечаниями"
    when 2.0...2.5
      "скорее недоволен, есть проблемы"
    when 1.5...2.0
      "недоволен покупкой, много замечаний"
    else
      "крайне негативный, разочарован"
    end

    instructions += "- КРИТИЧЕСКИ ВАЖНО: Итоговая оценка #{grade} из 5 - текст должен быть #{grade_interpretation}\n"

    # Добавляем информацию о детальных оценках если они есть
    if array_average && array_average.any?
      avg_rating = (array_average.sum.to_f / array_average.size).round(1)
      instructions += "- Средняя оценка по характеристикам: #{avg_rating}/5\n"

      # Анализируем разброс оценок
      if array_average.length > 1
        min_rating = array_average.min
        max_rating = array_average.max

        if max_rating - min_rating > 2.0
          instructions += "- ВАЖНО: Есть разброс в оценках (от #{min_rating} до #{max_rating}) - можешь упомянуть как сильные, так и слабые стороны\n"
        elsif grade >= 4.0 && array_average.any? { |r| r < 3.5 }
          instructions += "- Можно упомянуть небольшие недостатки (некоторые характеристики оценены ниже), но общий тон должен быть позитивным\n"
        elsif grade <= 2.5 && array_average.any? { |r| r >= 3.5 }
          instructions += "- Можно упомянуть отдельные положительные моменты, но общий тон должен быть критическим\n"
        end
      end
    end

    # Важное предупреждение о согласованности
    instructions += "- ЗАПРЕЩЕНО: Писать восторженный текст при низкой оценке или критический текст при высокой оценке!\n"

    instructions
  end

  def build_date_instructions(context)
    instructions = ""

    return instructions unless context[:time_description]

    # Текущая дата отзыва
    review_date = Date.parse(context[:review_date]) rescue Date.today
    current_month = review_date.month
    current_season = get_season_by_month(current_month)

    # Сезон шин
    tire_season = context[:season]
    tire_season_name = case tire_season
    when 1 then "летние"
    when 2 then "зимние"
    when 3 then "всесезонные"
    else "шины"
    end

    # Основная инструкция по времени
    instructions += "- ВАЖНО: Шины были куплены #{context[:time_description]}\n"
    instructions += "- Используй естественные формулировки времени: \"недавно\", \"пару месяцев назад\", \"прошлой зимой\" и т.д.\n"
    instructions += "- НЕ указывай точные даты покупки или отзыва\n"

    # Проверка на сезонное несоответствие
    if tire_season == 2  # зимние
      if [6, 7, 8].include?(current_month)  # лето
        instructions += "- ВНИМАНИЕ: Сейчас лето, но отзыв о зимних шинах - не пиши \"купил вчера\" или \"на днях купил зимние шины летом\"\n"
        instructions += "- Уместно упомянуть покупку осенью/зимой прошлого сезона\n"
      end
    elsif tire_season == 1  # летние
      if [12, 1, 2].include?(current_month)  # зима
        instructions += "- ВНИМАНИЕ: Сейчас зима, но отзыв о летних шинах - не пиши о недавней покупке летних шин зимой\n"
        instructions += "- Уместно упомянуть покупку весной/летом прошлого сезона\n"
      end
    end

    instructions
  end

  def get_season_by_month(month)
    case month
    when 12, 1, 2
      :winter
    when 3, 4, 5
      :spring
    when 6, 7, 8
      :summer
    when 9, 10, 11
      :autumn
    end
  end

  def build_geographic_restrictions
    instructions = ""

    # Запрет российских топонимов
    instructions += "- КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО упоминать любые российские города, регионы или топонимы\n"
    instructions += "- ЗАПРЕЩЕНО: Москва, Санкт-Петербург, Россия, российский и любые другие российские географические названия\n"
    instructions += "- РАЗРЕШЕНО: только украинские города (Киев, Харьков, Одесса, Львов, Днепр и т.д.)\n"
    instructions += "- При упоминании географии используй только Украину и украинские топонимы\n"

    instructions
  end

  def check_and_shorten_if_needed(review, context, max_length = 1000, tolerance = 0.10)
    return review if review.blank?

    # Допустимый лимит с учетом толерантности (1000 + 10% = 1100)
    acceptable_length = (max_length * (1 + tolerance)).to_i

    # Если длина в пределах нормы - возвращаем как есть
    return review if review.length <= acceptable_length

    # Длина превышена - логируем и переписываем
    Rails.logger.warn "Review too long: #{review.length} chars (limit: #{acceptable_length}). Shortening..."

    # Создаем промпт для сокращения
    shorten_prompt = build_shorten_prompt(review, context, max_length)

    # Оцениваем токены (примерно 4 символа = 1 токен для русского)
    estimated_tokens = (max_length / 4.0).round

    # Обрабатываем через AI для сокращения
    attempts = 0
    shortened_review = nil

    begin
      shorten_max_tokens = [estimated_tokens * 2, 2000].max
      response = @content_writer.generate_review(shorten_prompt, shorten_max_tokens, model_type: :review_generation)

      if response && response['choices'] && response['choices'][0]
        shortened_review = response['choices'][0]['message']['content'].strip
        shortened_review = clean_ai_response(shortened_review)
      end

      # Проверяем результат
      if shortened_review && shortened_review.length <= acceptable_length
        Rails.logger.info "Successfully shortened review: #{review.length} → #{shortened_review.length} chars"
        return shortened_review
      elsif shortened_review
        # Все еще длинный - отрезаем жестко
        Rails.logger.warn "AI didn't shorten enough (#{shortened_review.length}), truncating..."
        return truncate_review_safely(shortened_review, max_length)
      end

    rescue => e
      attempts += 1
      if attempts < 2
        Rails.logger.warn "Shortening failed, retrying: #{e.message}"
        sleep(1)
        retry
      else
        Rails.logger.error "Shortening failed after retries: #{e.message}"
        # В крайнем случае - безопасная обрезка
        return truncate_review_safely(review, max_length)
      end
    end

    # Fallback - безопасная обрезка
    truncate_review_safely(review, max_length)
  end

  def build_shorten_prompt(review, context, max_length)
    prompt = <<~PROMPT
      Перепиши следующий отзыв о шинах, СОКРАТИВ его длину, но сохранив основной смысл:

      ОРИГИНАЛЬНЫЙ ОТЗЫВ: "#{review}"

      КРИТИЧЕСКИЕ ТРЕБОВАНИЯ:
      - МАКСИМАЛЬНАЯ ДЛИНА: #{max_length} символов (сейчас #{review.length} - СЛИШКОМ ДЛИННЫЙ!)
      - Сохрани все важные факты (бренд, модель, опыт использования)
      - Убери лишние детали и повторения
      - Сохрани тональность и эмоциональную окраску
    PROMPT

    # Добавляем контекстные требования если есть
    if context[:gender]
      prompt += "- Сохрани #{context[:gender] == 'женщина' ? 'женский' : 'мужской'} род\n"
    end

    if context[:grade] && context[:grade] > 0
      tone = case context[:grade]
             when 4.0..5.0 then "позитивную"
             when 3.0...4.0 then "нейтрально-положительную"
             when 2.0...3.0 then "нейтрально-критическую"
             else "критическую"
             end
      prompt += "- Сохрани #{tone} тональность (оценка #{context[:grade]}/5)\n"
    end

    prompt += "\nВерни ТОЛЬКО сокращенный отзыв без комментариев."

    prompt
  end

  def truncate_review_safely(review, max_length)
    return review if review.length <= max_length

    # Обрезаем по предложениям, чтобы не было обрыва
    sentences = review.split(/([.!?]+)/)
    result = ""

    sentences.each_slice(2) do |sentence, punctuation|
      potential = result + sentence.to_s + punctuation.to_s
      break if potential.length > max_length
      result = potential
    end

    # Если не получилось собрать по предложениям, обрезаем жестко
    if result.empty? || result.length < (max_length * 0.5)
      result = review[0...max_length].strip
      # Добавляем многоточие если обрезали
      result += "..." unless result.end_with?('.', '!', '?')
    end

    result.strip
  end

  # Удаляет иероглифы и символы восточноазиатских языков (китайский, японский, корейский)
  def remove_asian_characters(text)
    return text if text.blank?

    # Паттерн для китайских, японских и корейских символов:
    # \p{Han} - китайские иероглифы (CJK Unified Ideographs)
    # \p{Hiragana} - японская хирагана
    # \p{Katakana} - японская катакана
    # \p{Hangul} - корейские символы
    asian_pattern = /[\p{Han}\p{Hiragana}\p{Katakana}\p{Hangul}]+/

    if text.match?(asian_pattern)
      Rails.logger.warn "Found Asian characters in generated review, removing them..."
      # Удаляем иероглифы
      text = text.gsub(asian_pattern, '')
      # Убираем двойные пробелы, которые могли образоваться
      text = text.gsub(/\s{2,}/, ' ')
      Rails.logger.info "Asian characters removed successfully"
    end

    text
  end

  # Заменяет стоп-слова (неестественные/рекламные фразы) на нормальные
  def replace_stop_words(text)
    return text if text.blank?
    return text unless defined?(REVIEW_STOP_WORDS_REPLACEMENTS)

    REVIEW_STOP_WORDS_REPLACEMENTS.each do |rule|
      text = text.gsub(rule[:pattern], rule[:replacement])
    end

    # Убираем двойные пробелы после замен
    text = text.gsub(/\s{2,}/, ' ').strip

    text
  end
end
