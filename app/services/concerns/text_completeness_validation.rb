# app/services/concerns/text_completeness_validation.rb
module TextCompletenessValidation
  # Проверяет целостность сгенерированного HTML-текста
  # Возвращает true, если текст полный и корректный
  def text_complete?(text, options = {})
    if text.blank?
      Rails.logger.warn "text_complete?: Text is blank"
      return false
    end

    # Опциональные параметры для кастомизации проверки
    required_ending_tag = options[:required_ending_tag] || '</p>'
    required_phrases = Array(options[:required_phrases])
    tags_to_check = options[:tags_to_check] || ['h2', 'h3', 'h4', 'p', 'ul', 'ol', 'li', 'a']

    # 1. Проверяем, что текст заканчивается корректно
    unless text.strip.end_with?(required_ending_tag)
      Rails.logger.warn "text_complete?: Text doesn't end with #{required_ending_tag}. Actual ending: #{text.strip[-20..-1]}"
      return false
    end

    # 2. Проверяем наличие обязательных фраз (если указаны)
    if required_phrases.any?
      phrases_present = required_phrases.any? { |phrase| text.include?(phrase) }
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
      if opening_count != closing_count
        Rails.logger.warn "text_complete?: Unbalanced <#{tag}> tags: #{opening_count} opening, #{closing_count} closing"
        return false
      end
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
