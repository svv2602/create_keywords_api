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

    if context[:brand]
      instructions += "- Обязательно используй бренд #{context[:brand]} в отзыве\n"
    end

    if context[:model]
      instructions += "- Обязательно упомяни модель #{context[:model]} в отзыве\n"
    end

    if context[:car]
      instructions += "- Можешь упомянуть автомобиль #{context[:car]} если уместно\n"
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

    instructions
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
    
    if analysis[:has_caps]
      instructions += "- В оригинале есть ЗАГЛАВНЫЕ буквы для эмоций - используй их умеренно\n"
    end
    
    if analysis[:has_exclamation]
      instructions += "- Сохрани эмоциональность с восклицательными знаками\n"
    end
    
    instructions += "- НЕ добавляй эмодзи в текст (они добавятся отдельно)\n"
    instructions += "- Пиши от первого лица как реальный пользователь\n"
    instructions += "- Избегай рекламных клише и шаблонных фраз\n"
    instructions += "- Результат должен звучать естественно и по-человечески\n"
    instructions += "- КРИТИЧЕСКИ ВАЖНО: Максимальная длина отзыва - 1000 символов! Не превышай этот лимит!\n"
    instructions += "\nВерни ТОЛЬКО переписанный отзыв без дополнительных комментариев."

    instructions
  end
  
  def process_through_ai(prompt, estimated_tokens)
    max_tokens = [estimated_tokens * 2, 150].max  # минимум 150 токенов для ответа
    
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
    
    # Убираем лишние кавычки и обрамления
    text = text.gsub(/^["«]|["»]$/, '')
    
    # Убираем префиксы типа "Отзыв:", "Переписанный отзыв:" и т.д.
    text = text.gsub(/^(отзыв|переписанный отзыв|результат):\s*/i, '')
    
    # Убираем эмодзи (они добавятся отдельно)
    text = text.gsub(/[😀-🙏🚀-🛿]/u, '')
    
    # Очищаем лишние пробелы
    text = text.gsub(/\s+/, ' ').strip
    
    return nil if text.blank?
    text
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
      response = @content_writer.generate_review(shorten_prompt, estimated_tokens * 2, model_type: :review_generation)

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
end
