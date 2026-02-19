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
    # Нормализуем HTML-теги (убираем лишние пробелы: "</p >" -> "</p>")
    normalized_text = text.strip.gsub(/<\s*\/\s*(\w+)\s*>/i, '</\1>')
    Rails.logger.info "Generated text length: #{normalized_text.length} characters"
    Rails.logger.info "Text ends with: #{normalized_text[-100..-1]}" if normalized_text.length > 100
    unless normalized_text.end_with?(required_ending_tag)
      Rails.logger.warn "text_complete?: Text doesn't end with required tag '#{required_ending_tag}'"
      return false
    end

    # 2. Проверяем наличие обязательных фраз (если указаны)
    if required_phrases.any?
      Rails.logger.info "Checking for CTA phrases: #{required_phrases.inspect}"
      required_phrases.each do |phrase|
        present = text.include?(phrase)
        Rails.logger.info "  '#{phrase}' present: #{present}"
      end
      text_downcased = text.downcase
      phrases_present = required_phrases.any? { |phrase| text_downcased.include?(phrase.downcase) }
      unless phrases_present
        Rails.logger.warn "text_complete?: None of required phrases found: #{required_phrases.inspect}"
        return false
      end
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
    if last_chars.match?(/<[^>]*$/)
      Rails.logger.warn "text_complete?: Text ends with incomplete tag"
      return false
    end

    Rails.logger.info "text_complete?: All checks passed ✓"
    true
  end

  # Логирует предупреждение об обрезанном тексте
  def log_incomplete_text_warning(identifier)
    Rails.logger.warn("Generated text appears to be truncated for: #{identifier}")
  end
end
