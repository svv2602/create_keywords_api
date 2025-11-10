# app/services/concerns/text_completeness_validation.rb
module TextCompletenessValidation
  # Проверяет целостность сгенерированного HTML-текста
  # Возвращает true, если текст полный и корректный
  def text_complete?(text, options = {})
    return false if text.blank?

    # Опциональные параметры для кастомизации проверки
    required_ending_tag = options[:required_ending_tag] || '</p>'
    required_phrases = Array(options[:required_phrases])
    tags_to_check = options[:tags_to_check] || ['h2', 'h3', 'h4', 'p', 'ul', 'ol', 'li', 'a']

    # 1. Проверяем, что текст заканчивается корректно
    return false unless text.strip.end_with?(required_ending_tag)

    # 2. Проверяем наличие обязательных фраз (если указаны)
    if required_phrases.any?
      phrases_present = required_phrases.any? { |phrase| text.include?(phrase) }
      return false unless phrases_present
    end

    # 3. Проверяем сбалансированность HTML-тегов
    tags_to_check.each do |tag|
      opening_count = text.scan(/<#{tag}(?:\s[^>]*)?>/).count
      closing_count = text.scan(/<\/#{tag}>/).count

      # Если есть несбалансированность, текст считается обрезанным
      return false if opening_count != closing_count
    end

    # 4. Проверяем, что текст не заканчивается незавершенным тегом или словом
    # Если последние 50 символов содержат открывающий тег без закрывающего - текст обрезан
    last_chars = text[-50..-1] || text
    return false if last_chars.match?(/<[^>]*$/)  # Незавершенный тег в конце

    true
  end

  # Логирует предупреждение об обрезанном тексте
  def log_incomplete_text_warning(identifier)
    Rails.logger.warn("Generated text appears to be truncated for: #{identifier}")
  end
end
