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

    # Нормализуем HTML-теги для ВСЕХ проверок (убираем лишние пробелы: "</p >" -> "</p>", "<p >" -> "<p>")
    normalized_text = text.strip
      .gsub(/<\s*\/\s*(\w+)\s*>/i, '</\1>')   # </p > -> </p>
      .gsub(/<\s*(\w+)\s*>/i, '<\1>')          # <p > -> <p>

    # 1. Проверяем, что текст заканчивается корректно
    Rails.logger.info "Generated text length: #{normalized_text.length} characters"
    Rails.logger.info "Text ends with: #{normalized_text[-100..-1]}" if normalized_text.length > 100
    unless normalized_text.end_with?(required_ending_tag)
      Rails.logger.warn "text_complete?: Text doesn't end with required tag '#{required_ending_tag}'"
      return false
    end

    # 2. Проверяем наличие обязательных фраз (если указаны)
    if required_phrases.any?
      # Бесспейсовое сравнение: убираем пробелы из текста И из фраз
      # Это гарантированно находит CTA даже в "рассыпанном" тексте LLM
      cta_search_text = normalize_for_cta_search(normalized_text).downcase
      Rails.logger.info "Checking for CTA phrases: #{required_phrases.inspect}"
      required_phrases.each do |phrase|
        present = cta_search_text.include?(phrase.downcase.gsub(/\s+/, ''))
        Rails.logger.info "  '#{phrase}' present: #{present}"
      end
      phrases_present = required_phrases.any? { |phrase| cta_search_text.include?(phrase.downcase.gsub(/\s+/, '')) }
      unless phrases_present
        Rails.logger.warn "text_complete?: None of required phrases found: #{required_phrases.inspect}"
        return false
      end
    end

    # 3. Проверяем сбалансированность HTML-тегов (используем normalized_text)
    tags_to_check.each do |tag|
      opening_count = normalized_text.scan(/<#{tag}(?:\s[^>]*)?>/).count
      closing_count = normalized_text.scan(/<\/#{tag}>/).count

      if opening_count != closing_count
        Rails.logger.warn "text_complete?: Unbalanced <#{tag}> tags: #{opening_count} opening, #{closing_count} closing"
        return false
      end
    end

    # 4. Проверяем, что текст не заканчивается незавершенным тегом
    last_chars = normalized_text[-50..-1] || normalized_text
    if last_chars.match?(/<[^>]*$/)
      Rails.logger.warn "text_complete?: Text ends with incomplete tag"
      return false
    end

    Rails.logger.info "text_complete?: All checks passed ✓"
    true
  end

  # Нормализует текст для поиска CTA-фраз
  # Использует бесспейсовое сравнение: убирает ВСЕ пробелы из текста
  # Это гарантированно находит CTA даже в "рассыпанном" тексте LLM:
  # "о ф о р м і т и з а м о в л е н н я он лай н" → "оформітизамовленняонлайн"
  def normalize_for_cta_search(text)
    # Убираем HTML-теги и все пробелы для надёжного поиска подстроки
    text.gsub(/<[^>]*>/, '').gsub(/\s+/, '')
  end

  # Логирует предупреждение об обрезанном тексте
  def log_incomplete_text_warning(identifier)
    Rails.logger.warn("Generated text appears to be truncated for: #{identifier}")
  end
end
