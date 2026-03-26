# app/services/concerns/html_sanitization.rb
# Общий модуль постобработки HTML, сгенерированного LLM.
# Подключается в CarSeoTextGenerator, SeoTextGenerator и других генераторах.
module HtmlSanitization
  # ---- Константы для гомоглифов и кириллических тегов ----

  CYRILLIC_HOMOGLYPHS = {
    'а' => 'a', 'е' => 'e', 'о' => 'o', 'р' => 'p', 'с' => 'c',
    'х' => 'x', 'у' => 'y', 'і' => 'i',
    'А' => 'A', 'В' => 'B', 'Е' => 'E', 'К' => 'K', 'М' => 'M',
    'Н' => 'H', 'О' => 'O', 'Р' => 'P', 'С' => 'C', 'Т' => 'T', 'Х' => 'X'
  }.freeze
  CYRILLIC_HOMOGLYPH_PATTERN = /[#{CYRILLIC_HOMOGLYPHS.keys.join}]/

  CYRILLIC_TAG_MAP = {
    'п' => 'p', 'р' => 'p',
    'ли' => 'li', 'лі' => 'li',
    'ул' => 'ul',
    'ол' => 'ol',
  }.freeze

  # ---- Основной pipeline ----

  # Универсальная постобработка HTML от LLM.
  # Вызывающий класс может переопределить или дополнить, вызвав super.
  def sanitize_llm_html(text)
    return '' if text.blank?

    # 1. Кодировки и спецсимволы
    text = remove_asian_characters(text)
    text = normalize_unicode_brackets(text)
    text = decode_html_entity_tags(text)

    # 2. Комментарии и мусор
    text = text.gsub(/<!--.*?-->/m, '')

    # 3. Кириллица в тегах и URL
    text = fix_cyrillic_tag_names(text)
    text = fix_broken_a_tags(text)
    text = fix_cyrillic_in_html_tags(text)
    text = fix_cyrillic_in_urls(text)
    text = text.gsub(/<\s*>/, '') # пустые теги <>

    # 4. Пробелы в URL
    text = fix_all_href_spaces(text)

    # 5. Текстовые нормализации
    text = fix_internet_magazin(text)

    # 6. Ссылки
    text = sanitize_links(text)
    text = deduplicate_links(text)

    # 7. Изображения и &nbsp;
    text = remove_images(text)
    text = remove_nbsp_artifacts(text)

    # 8. Нежелательные теги документа
    text = strip_document_tags(text)

    # 9. Удаляем атрибуты
    text = strip_unwanted_attributes(text)

    # 10. Починка сломанных тегов от LLM
    text = fix_bracket_artifacts(text)
    text = fix_garbled_character_sequences(text)
    text = remove_orphaned_angle_brackets(text)

    # 11. Балансировка и финализация
    text = balance_html_tags(text)
    text = wrap_trailing_text_in_p(text)

    # 12. Заголовки
    text = capitalize_headings(text)

    # 13. Финальная очистка пробелов
    text = text.gsub(/\s+/, ' ')
    text = text.gsub(/>\s+</, '><')

    text.strip
  end

  # ---- Методы-фиксы (алфавитный порядок) ----

  # Балансирует HTML-теги: добавляет недостающие / удаляет лишние закрывающие теги
  def balance_html_tags(text)
    return text if text.blank?

    tags_to_balance = ['h2', 'h3', 'h4', 'ul', 'ol', 'li', 'p']

    tags_to_balance.each do |tag|
      opening_count = text.scan(/<#{tag}(?:\s[^>]*)?>/).count
      closing_count = text.scan(/<\/#{tag}>/).count

      if opening_count > closing_count
        missing = opening_count - closing_count
        Rails.logger.info "Balanced HTML: added #{missing} missing </#{tag}> tag(s)"
        if tag != 'p' && text.strip.end_with?('</p>')
          insertion = "</#{tag}>" * missing
          text = text.sub(/<\/p>(\s*)\z/, "#{insertion}</p>\\1")
        else
          missing.times { text += "</#{tag}>" }
        end
      elsif closing_count > opening_count
        excess = closing_count - opening_count
        Rails.logger.info "Balanced HTML: removed #{excess} extra </#{tag}> tag(s)"
        depth = 0
        removed = 0
        text = text.gsub(/<(\/?)#{tag}(?:\s[^>]*)?>/) do |match|
          if $1 == '/'
            if depth <= 0 && removed < excess
              removed += 1
              ''
            else
              depth -= 1
              match
            end
          else
            depth += 1
            match
          end
        end
      end
    end

    text
  end

  # Капитализирует первую букву текста в заголовках h1-h6
  def capitalize_headings(text)
    return text if text.blank?

    text.gsub(/<(h[1-6])([^>]*)>(.*?)<\/\1>/im) do
      tag = $1
      attrs = $2
      content = $3
      capitalized = content.sub(/\A(\s*(?:<[^>]+>)*)(\p{L})/i) { "#{$1}#{$2.upcase}" }
      "<#{tag}#{attrs}>#{capitalized}</#{tag}>"
    end
  end

  # Декодирует HTML-entities, формирующие теги: &lt;a href="..."&gt; → <a href="...">
  def decode_html_entity_tags(text)
    return text if text.blank?

    text = text.gsub(/&lt;(.*?)&gt;/) do
      inner = $1.strip
      if inner.match?(/\A\/?[a-zA-Zа-яА-ЯіІїЇєЄґҐ]/)
        decoded = inner.gsub('&quot;', '"').gsub('&amp;', '&').gsub('&apos;', "'")
        "<#{decoded}>"
      else
        "&lt;#{$1}&gt;"
      end
    end

    text = text.gsub('&gt;', '>')
    text.gsub('&lt;', '<')
  end

  # Дедупликация ссылок: оставляет первое вхождение каждого href
  def deduplicate_links(text)
    return text if text.blank?

    seen_hrefs = Set.new

    text.gsub(/<a\s+[^>]*href="([^"]*)"[^>]*>(.*?)<\/a>/im) do
      href = $1
      anchor = $2
      normalized = href.downcase.chomp('/')

      if seen_hrefs.include?(normalized)
        Rails.logger.info "Deduplicate links: removing duplicate href=\"#{href}\", keeping anchor \"#{anchor}\""
        anchor
      else
        seen_hrefs.add(normalized)
        $&
      end
    end
  end

  # Комплексное исправление пробелов во ВСЕХ href="..." значениях
  def fix_all_href_spaces(text)
    return text if text.blank?

    text.gsub(/href="([^"]*)"/) do |match|
      href = $1
      original_href = href.dup

      href = href.gsub(/\s*\/\s*/, '/')
      href = href.gsub(/([whr])\s+(\d+)/, '\1-\2')
      href = href.gsub(/\/([whr])(\d+)(?=\/)/, '/\1-\2')
      href = href.gsub(/\s+/, '')

      if href != original_href
        Rails.logger.info "Fixed spaces in href: #{original_href} -> #{href}"
      end
      "href=\"#{href}\""
    end
  end

  # Починка скобочных артефактов от LLM: <]/li] -> </li>, [li] -> <li>
  def fix_bracket_artifacts(text)
    return text if text.blank?

    text = text.gsub(/<\]\/(\w+)\]/, '</\1>')
    text = text.gsub(/\[\/(\w+)\]/, '</\1>')
    text = text.gsub(/<\/(\w+)\]/, '</\1>')
    text = text.gsub(/<\](\w+)\]/, '<\1>')
    text = text.gsub(/\[(\w+)\](?=[^a-z])/i, '<\1>')

    # Исправляем закрывающие теги с пробелами и мусором
    text.gsub(/<\s*\/+\s*([\w][\w\s]*?)\s*>/i) do
      "</#{$1.gsub(/\s+/, '')}>"
    end
  end

  # Восстанавливает сломанные <a> теги (DeepSeek разбивает href на символы)
  def fix_broken_a_tags(text)
    return text if text.blank?

    text.gsub(/<a\s+([^>]*?)>/i) do |match|
      attrs = $1.strip
      next match if attrs.match?(/\bhref\s*=/i)

      urls = attrs.scan(/(?:\w+)="([^"]*)"/).flatten.select { |v| v.include?('/') }
      if urls.any?
        url = urls.max_by(&:length)
        Rails.logger.info "Fixed broken <a> tag: #{match[0..80]} → <a href=\"#{url}\">"
        "<a href=\"#{url}\">"
      else
        match
      end
    end
  end

  # Нормализует кириллические гомоглифы в HTML-тегах: <а hreеf=...> → <a href=...>
  def fix_cyrillic_in_html_tags(text)
    return text if text.blank?

    text.gsub(/<[^>]+>/) do |tag|
      original = tag
      fixed = tag.gsub(CYRILLIC_HOMOGLYPH_PATTERN) { |c| CYRILLIC_HOMOGLYPHS[c] || c }
      fixed = fixed.gsub(/[хhx][рrp][еe]+[фf]/i, 'href')
      if fixed != original
        Rails.logger.info "Fixed Cyrillic homoglyphs in tag: #{original[0..60]} → #{fixed[0..60]}"
      end
      fixed
    end
  end

  # Нормализует URL-пути в href-атрибутах
  def fix_cyrillic_in_urls(text)
    return text if text.blank?

    text.gsub(/<a\s+href="([^"]*)"[^>]*>(.*?)<\/a>/im) do |match|
      href = $1
      anchor = $2
      fixed = href.dup

      fixed = fixed.gsub(/(?<!:)\/{2,}/, '/')
      fixed = fixed.gsub(/\/ya(?=\/)/i, '/ua')
      fixed = fixed.gsub(/\/я(?=\/)/i, '/ua')
      fixed = fixed.gsub(/\/sh[a-zA-Zа-яА-ЯіІїЇєЄґҐ]{1,4}y(?=\/)/i, '/shiny')
      fixed = fixed.gsub(/\/(?:шин[иыі]|cxин[иыі])(?=\/)/i, '/shiny')
      fixed = fixed.gsub(/\/[вВ][-‐‑–—](\d)/, '/w-\1')
      fixed = fixed.gsub(/\/[нН][-‐‑–—](\d)/, '/h-\1')
      fixed = fixed.gsub(/\/[рР][-‐‑–—](\d)/, '/r-\1')
      fixed = fixed.gsub(/[‐‑–—]/, '-')
      fixed = fixed.gsub(/\/shiny\/shiny-/, '/shiny/')
      fixed = fixed.gsub(/\/shiny\/shiny\//, '/shiny/')
      fixed = fixed.gsub(/\/(?:зимов[іі]|зимн[іиіе]{1,2})(?=\/)/i, '/zimnie')
      fixed = fixed.gsub(/\/(?:літн[іі]|летн[іиіе]{1,2})(?=\/)/i, '/letnie')
      fixed = fixed.gsub(/\/всесезонн[іиіе]{1,2}(?=\/)/i, '/vsesezonie')

      if fixed.match?(/[а-яА-ЯіІїЇєЄґҐёЁ]/)
        Rails.logger.warn "Removed link with Cyrillic URL: #{href} (anchor: #{anchor})"
        anchor
      else
        if fixed != href
          Rails.logger.info "Fixed URL path: #{href} → #{fixed}"
        end
        "<a href=\"#{fixed}\">#{anchor}</a>"
      end
    end
  end

  # Заменяет кириллические имена тегов на латинские: <п> → <p>, </ли> → </li>
  def fix_cyrillic_tag_names(text)
    return text if text.blank?

    cyrillic_names = CYRILLIC_TAG_MAP.keys.join('|')

    text = text.gsub(/<\s*(\/?)\s*(#{cyrillic_names})\s*>/i) do
      slash = $1
      name = CYRILLIC_TAG_MAP[$2.downcase] || $2
      "<#{slash}#{name}>"
    end

    text = text.gsub(/<[—–-]\s*(#{cyrillic_names})\s*[—–-]>/i) do
      name = CYRILLIC_TAG_MAP[$1.downcase] || $1
      "</#{name}>"
    end

    text
  end

  # Обнаруживает и удаляет абзацы с посимвольным выводом LLM (DeepSeek issue)
  def fix_garbled_character_sequences(text)
    return text if text.blank?

    text.gsub(/<p[^>]*>([^<]*)<\/p>/i) do |match|
      content = $1.strip
      words = content.split(/\s+/)

      if words.length >= 8
        single_char_count = words.count { |w| w.length == 1 }
        ratio = single_char_count.to_f / words.length

        if ratio > 0.5
          Rails.logger.warn "Removed garbled paragraph (#{(ratio * 100).round}% single-char tokens): #{content[0..80]}..."
          ''
        else
          fixed_content = content.gsub(/(?<=[а-яА-ЯіІїЇєЄґҐ])\s+(?=[а-яА-ЯіІїЇєЄґҐ]\s+[а-яА-ЯіІїЇєЄґҐ](?:\s|$))/) { '' }
          fixed_content = fixed_content.gsub(/\b([а-яА-ЯіІїЇєЄґҐ])\s+([а-яА-ЯіІїЇєЄґҐ])\b/, '\1\2')

          if fixed_content != content
            Rails.logger.info "Repaired spaced-out text in paragraph: #{content[0..60]} → #{fixed_content[0..60]}"
          end

          repaired_words = fixed_content.split(/\s+/)
          if repaired_words.length > 15
            avg_length = repaired_words.sum(&:length).to_f / repaired_words.length
            if avg_length < 3.0
              Rails.logger.warn "Removed paragraph with abnormally low avg word length (#{avg_length.round(1)}): #{fixed_content[0..80]}..."
              next ''
            end
          end

          fixed_content != content ? match.sub(content, fixed_content) : match
        end
      else
        match
      end
    end
  end

  # Нормализует написание "інтернет-магазин" / "интернет-магазин"
  def fix_internet_magazin(text)
    return text if text.blank?

    text = text.gsub(/інтернет\s*[1+&\s-]+\s*магазин/i, 'інтернет-магазин')
    text.gsub(/интернет\s*[1+&\s-]+\s*магазин/i, 'интернет-магазин')
  end

  # Нормализует Unicode-скобки от LLM и пробелы внутри тегов
  def normalize_unicode_brackets(text)
    return text if text.blank?

    text = text.gsub(/[〈＜]/, '<').gsub(/[〉＞]/, '>')
    text.gsub(/<\s+(\/?\w+)/, '<\1')
  end

  # Удаляет иероглифы и символы восточноазиатских языков
  def remove_asian_characters(text)
    asian_pattern = /[\p{Han}\p{Hiragana}\p{Katakana}\p{Hangul}]+/

    if text.match?(asian_pattern)
      Rails.logger.warn "Found Asian characters in generated text, removing them..."
      text = text.gsub(asian_pattern, '')
      text = text.gsub(/\s{2,}/, ' ')
    end

    text
  end

  # Удаляет все <img> теги из текста
  def remove_images(text)
    return text if text.blank?

    cleaned = text.gsub(/<img\s[^>]*>/i, '')
    cleaned.gsub(/<p>\s*<\/p>/i, '')
  end

  # Удаляет пустые теги с &nbsp; и лишние &nbsp; между тегами
  def remove_nbsp_artifacts(text)
    return text if text.blank?

    text = text.gsub(/<p>\s*(?:&nbsp;\s*)+<\/p>/i, '')
    text.gsub(/(?:<\/li>|<\/a>)\s*(?:&nbsp;\s*)+/i) { |m| m.match(/<\/\w+>/)[0] }
  end

  # Удаляем осиротевшие > (остатки сломанных тегов LLM)
  def remove_orphaned_angle_brackets(text)
    return text if text.blank?

    text = text.gsub(/(>)\s*>/, '\1')
    text = text.gsub(/^\s*>\s*$/m, '')
    text.gsub(/^\s*>(?=\s*[\wа-яА-ЯіІїЇєЄґҐ])/m, '')
  end

  # Очищает ссылки: удаляет безанкорные и нормализует домены prokoleso.*
  def sanitize_links(text)
    return text if text.blank?

    text = text.gsub(/<a\s+[^>]*href="[^"]*"[^>]*>\s*<\/a>/i, '')
    text.gsub(/href="https?:\/\/prokoleso\.[a-z]+(\.[a-z]+)?/i, 'href="')
  end

  # Удаляет нежелательные теги документа и markdown
  def strip_document_tags(text)
    return text if text.blank?

    text = text.gsub(/```html\s*/i, '').gsub(/```\s*$/m, '').gsub(/^```\s*/m, '')
    text = text.gsub(/\*{2,}/, '')
    text = text.gsub(/<!DOCTYPE[^>]*>/i, '')
    text = text.gsub(/<\/?html[^>]*>/i, '')
    text = text.gsub(/<\/?body[^>]*>/i, '')
    text = text.gsub(/<\/?head[^>]*>/i, '')
    text = text.gsub(/<meta[^>]*>/i, '')
    text = text.gsub(/<title[^>]*>.*?<\/title>/im, '')
    text = text.gsub(/<\/?div[^>]*>/i, '')
    text = text.gsub(/<style[^>]*>.*?<\/style>/im, '')
    text.gsub(/<\/?(html|body|head|div|style|p|h[1-6]|ul|ol|li|a)[^>]*$/i, '')
  end

  # Удаляет атрибуты class, style, target из тегов
  def strip_unwanted_attributes(text)
    return text if text.blank?

    text = text.gsub(/\s*class="[^"]*"/, '')
    text = text.gsub(/\s*style="[^"]*"/, '')
    text.gsub(/\s*target="[^"]*"/, '')
  end

  # Оборачивает осиротевший текст после последнего тега в <p>...</p>
  def wrap_trailing_text_in_p(text)
    return text if text.blank?
    return text if text.strip.end_with?('</p>')

    last_close = text.rindex(/<\/(?:p|ul|ol|h[2-4]|li)>/i)
    if last_close
      end_of_tag = text.index('>', last_close) + 1
      tail = text[end_of_tag..].strip
      if tail.length > 0
        text[0...end_of_tag] + "<p>#{tail}</p>"
      else
        text + '</p>'
      end
    else
      text + '</p>'
    end
  end
end
