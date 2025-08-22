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
    
    # Финальная обработка
    finalize_review(processed_review, analysis, context)
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
end
