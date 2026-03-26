# app/services/car_seo_text_generator.rb
class CarSeoTextGenerator
  include StringProcessing
  include TextCompletenessValidation

  # Классификация брендов шин по сегментам
  TIRE_BRANDS_BY_SEGMENT = {
    premium: %w[Michelin Bridgestone Continental Pirelli Goodyear Yokohama Hankook Nokian],
    mid: %w[Toyo Kumho BFGoodrich Nexen Firestone Kleber Uniroyal LASSA Laufenn],
    budget: %w[Matador Debica Barum Sava Taurus ORIUM Sailun Roadstone Doublestar HABILEAD Grenlander Firemax Premiorri Rydanz]
  }.freeze



  def initialize(params)
    @brand = params[:brand]
    @model = params[:model]
    @language = params[:language] || 'ru'
    @typical_sizes = params[:typical_sizes] || []
    @generation = params[:generation]
    @production_years = params[:production_years]
    @body_type = params[:body_type]
    @car_class = params[:car_class]
  end

  def generate
    validate_params!

    # Пытаемся получить информацию из Wikipedia
    @wikipedia_info = fetch_wikipedia_info

    prompt = build_prompt

    # Генерация текста через AI
    # Используем фиксированный большой лимит токенов для предотвращения обрезания
    # 5000 токенов (~3750 слов) достаточно для полного текста с CTA
    max_tokens = 5000

    Rails.logger.info "Wikipedia info present: #{@wikipedia_info.present?}"
    Rails.logger.info "Using max_tokens: #{max_tokens}"

    response = ContentWriter.new.write_seo_text(prompt, max_tokens)

    if response
      text = response['choices'][0]['message']['content'].strip

      Rails.logger.info "Raw AI response length: #{text.length} characters"
      Rails.logger.info "Raw text encoding: #{text.encoding}"
      Rails.logger.info "Raw text sample (first 200 chars): #{text[0..200]}"

      text = clean_html_text(text)

      Rails.logger.info "After clean_html_text length: #{text.length}"
      Rails.logger.info "Final text sample (last 200 chars): #{text[-200..-1]}"

      # Проверка на обрезанный текст
      cta_phrases = @language == 'ua' ?
        ['замовлення онлайн', 'замовити онлайн', 'оформіть замовлення', 'оформте замовлення', 'зробіть замовлення'] :
        ['заказ онлайн', 'заказать онлайн', 'оформите заказ', 'оформить заказ', 'сделайте заказ']

      # Проверка целостности текста
      unless text_complete?(text, required_phrases: cta_phrases)
        log_incomplete_text_warning("#{@brand} #{@model} (#{@language})")
        Rails.logger.warn "Text appears incomplete, attempting to complete it..."

        # Пытаемся автоматически завершить обрезанный текст
        completed_text = complete_truncated_text(text, max_tokens)

        if completed_text && text_complete?(completed_text, required_phrases: cta_phrases)
          Rails.logger.info "Text successfully completed!"
          text = completed_text
        else
          Rails.logger.error "Failed to complete text"
          return { error: 'Generated text is incomplete. Please try again or reduce text length requirements.' }
        end
      end

      {
        text: text,
        brand: @brand,
        model: @model,
        language: @language,
        generated_at: Time.current
      }
    else
      { error: 'Failed to generate text' }
    end
  rescue => e
    { error: e.message }
  end

  private

  def validate_params!
    raise ArgumentError, 'Brand is required' if @brand.blank?
    raise ArgumentError, 'Model is required' if @model.blank?
    raise ArgumentError, 'Language must be ru or ua' unless %w[ru ua].include?(@language)
    raise ArgumentError, 'Typical sizes are required' if @typical_sizes.blank?
  end

  def fetch_wikipedia_info
    return nil if @brand.blank? || @model.blank?

    require 'net/http'
    require 'json'

    wiki_lang = @language == 'ua' ? 'uk' : 'ru'

    # Формируем название страницы (заменяем пробелы на подчеркивания)
    page_title = "#{@brand}_#{@model}".gsub(' ', '_')

    Rails.logger.info "Fetching Wikipedia info for: #{page_title} (#{wiki_lang})"

    # Пробуем прямой запрос к Wikipedia REST API
    url = URI("https://#{wiki_lang}.wikipedia.org/api/rest_v1/page/summary/#{URI.encode_www_form_component(page_title)}")

    begin
      response = Net::HTTP.start(url.host, url.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
        request = Net::HTTP::Get.new(url)
        request['User-Agent'] = 'ProKoleso SEO Bot/1.0'
        http.request(request)
      end

      if response.code == '200'
        data = JSON.parse(response.body)
        if data['extract'].present?
          Rails.logger.info "Wikipedia: Found article directly - #{page_title}"
          return data['extract']
        end
      end
    rescue => e
      Rails.logger.warn "Wikipedia direct request failed: #{e.message}"
    end

    # Если прямой запрос не сработал - используем поиск
    begin
      search_url = URI("https://#{wiki_lang}.wikipedia.org/w/rest.php/v1/search/page?q=#{URI.encode_www_form_component("#{@brand} #{@model}")}&limit=1")
      search_response = Net::HTTP.start(search_url.host, search_url.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
        request = Net::HTTP::Get.new(search_url)
        request['User-Agent'] = 'ProKoleso SEO Bot/1.0'
        http.request(request)
      end

      if search_response.code == '200'
        search_data = JSON.parse(search_response.body)
        if search_data['pages']&.any?
          page_key = search_data['pages'][0]['key']
          Rails.logger.info "Wikipedia: Found via search - #{page_key}"

          # Получаем саммари найденной страницы
          summary_url = URI("https://#{wiki_lang}.wikipedia.org/api/rest_v1/page/summary/#{URI.encode_www_form_component(page_key)}")
          summary_response = Net::HTTP.start(summary_url.host, summary_url.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
            request = Net::HTTP::Get.new(summary_url)
            request['User-Agent'] = 'ProKoleso SEO Bot/1.0'
            http.request(request)
          end

          if summary_response.code == '200'
            summary_data = JSON.parse(summary_response.body)
            return summary_data['extract'] if summary_data['extract'].present?
          end
        end
      end
    rescue => e
      Rails.logger.warn "Wikipedia search failed: #{e.message}"
    end

    Rails.logger.info "Wikipedia: No article found for #{@brand} #{@model}"
    nil
  rescue => e
    Rails.logger.error "Wikipedia fetch error: #{e.message}"
    nil
  end

  def clean_html_text(text)
    # Удаляем лишние пробелы и переносы строк, но сохраняем структуру HTML
    # Также удаляем возможные div, классы и стили

    # Удаляем иероглифы и символы восточноазиатских языков
    text = remove_asian_characters(text)

    # Нормализуем Unicode-скобки от LLM: 〈 → <, 〉 → >, ＜ → <, ＞ → >
    text = text.gsub(/[〈＜]/, '<').gsub(/[〉＞]/, '>')
    # Нормализуем пробелы после < в тегах: < p> → <p>, < /p> → </p>
    text = text.gsub(/<\s+(\/?\w+)/, '<\1')

    # Декодируем HTML-entities, формирующие теги: &lt;a href="..."&gt; → <a href="...">
    text = decode_html_entity_tags(text)

    # Удаляем HTML-комментарии (LLM генерирует <!--/а--> вместо </a>)
    text = text.gsub(/<!--.*?-->/m, '')

    # Заменяем кириллические теги-слова на HTML: <п> → <p>, </ли> → </li>, <—ли—> → </li>
    text = fix_cyrillic_tag_names(text)

    # Восстанавливаем сломанные <a> теги (DeepSeek разбивает href на символы)
    text = fix_broken_a_tags(text)

    # Нормализуем кириллические гомоглифы в HTML-тегах: <а hreеf=...> → <a href=...>
    text = fix_cyrillic_in_html_tags(text)

    # Нормализуем URL-пути в href (кириллица в /shiny/, двойные слеши)
    text = fix_cyrillic_in_urls(text)

    # Удаляем пустые теги <> (остатки от сломанных тегов LLM)
    text = text.gsub(/<\s*>/, '')

    # Комплексное исправление пробелов во всех href (заменяет fix_spaces_in_tire_urls)
    text = fix_all_href_spaces(text)

    # Удаляем циклические ссылки на текущую модель автомобиля
    text = remove_self_referencing_links(text)

    # Нормализуем "інтернет-магазин" / "интернет-магазин" (убираем пробелы, спецсимволы)
    text = fix_internet_magazin(text)

    # Исправляем или удаляем некорректные ссылки на типоразмеры
    text = fix_tire_size_links(text)

    # Валидируем анкоры ссылок на типоразмеры (анкор должен содержать размер)
    text = validate_tire_link_anchors(text)

    # Очищаем ссылки: удаляем безанкорные и нормализуем домены
    text = sanitize_links(text)
    # Дедупликация ссылок: оставляем первое вхождение каждого href
    text = deduplicate_links(text)
    # Исправляем CTA: ссылка-предложение → plain text
    text = fix_cta_link_wrapping(text)
    # Удаляем изображения из сгенерированного текста
    text = remove_images(text)
    # Удаляем пустые теги с &nbsp; и лишние &nbsp; между тегами
    text = text.gsub(/<p>\s*(?:&nbsp;\s*)+<\/p>/i, '')
    text = text.gsub(/(?:<\/li>|<\/a>)\s*(?:&nbsp;\s*)+/i) { |m| m.match(/<\/\w+>/)[0] }
    # Заголовки h1-h6 должны начинаться с заглавной буквы
    text = capitalize_headings(text)

    # Удаляем markdown-разметку
    text = text.gsub(/```html\s*/, '').gsub(/```\s*$/, '')
    text = text.gsub(/\*{2,}/, '')  # **жирный** → жирный

    # Удаляем все нежелательные теги (даже если они обрезаны или без закрывающих скобок)
    text = text.gsub(/<!DOCTYPE[^>]*>/i, '')                 # Удаляем DOCTYPE
    text = text.gsub(/<\/?html[^>]*>/i, '')                  # Удаляем <html> и </html>
    text = text.gsub(/<\/?body[^>]*>/i, '')                  # Удаляем <body> и </body>
    text = text.gsub(/<\/?head[^>]*>/i, '')                  # Удаляем <head> и </head>
    text = text.gsub(/<meta[^>]*>/i, '')                     # Удаляем meta теги
    text = text.gsub(/<title[^>]*>.*?<\/title>/im, '')       # Удаляем title
    text = text.gsub(/<\/?div[^>]*>/i, '')                   # Удаляем div
    text = text.gsub(/<style[^>]*>.*?<\/style>/im, '')       # Удаляем style теги

    # Удаляем обрезанные теги в конце (например "</html" или "</p" без закрывающей скобки)
    text = text.gsub(/<\/?(html|body|head|div|style|p|h[1-6]|ul|ol|li|a)[^>]*$/i, '')

    # Исправляем закрывающие теги с пробелами и мусором: </p >, < /p>, < //l i> → </p>, </li>
    text = text.gsub(/<\s*\/+\s*([\w][\w\s]*?)\s*>/i) do
      "</#{$1.gsub(/\s+/, '')}>"
    end

    # Исправляем сломанные теги от AI: <]/li] -> </li>, <]/p] -> </p> и т.д.
    # AI иногда генерирует квадратные скобки вместо угловых
    text = text.gsub(/<\]\/(\w+)\]/, '</\1>')   # <]/li] -> </li>
    text = text.gsub(/\[\/(\w+)\]/, '</\1>')    # [/li] -> </li>
    text = text.gsub(/<\/(\w+)\]/, '</\1>')     # </li] -> </li>
    text = text.gsub(/<\](\w+)\]/, '<\1>')      # <]li] -> <li>
    text = text.gsub(/\[(\w+)\](?=[^a-z])/i, '<\1>') # [li] -> <li> (но не [слово])

    # Исправляем посимвольный вывод LLM ("о ф о р м і т и" → "оформіти")
    text = fix_garbled_character_sequences(text)

    # Удаляем осиротевшие > (остатки сломанных тегов LLM)
    text = text.gsub(/(>)\s*>/, '\1')       # </p>> → </p>
    text = text.gsub(/^\s*>\s*$/m, '')      # строки состоящие только из >
    text = text.gsub(/^\s*>(?=\s*[\wа-яА-ЯіІїЇєЄґҐ])/m, '') # > перед текстом в начале строки

    # Балансируем HTML-теги (LLM иногда забывает закрывающие/лишние теги)
    text = balance_html_tags(text)

    # Если текст не заканчивается на </p>, оборачиваем хвост в <p>...</p>
    unless text.strip.end_with?('</p>')
      # Находим позицию после последнего закрывающего блочного тега
      last_close = text.rindex(/<\/(?:p|ul|ol|h[2-4]|li)>/i)
      if last_close
        end_of_tag = text.index('>', last_close) + 1
        tail = text[end_of_tag..].strip
        if tail.length > 0
          text = text[0...end_of_tag] + "<p>#{tail}</p>"
        else
          text += '</p>'
        end
      else
        text += '</p>'
      end
    end

    # Удаляем атрибуты
    text = text.gsub(/\s*class="[^"]*"/,  '')                 # Удаляем классы
    text = text.gsub(/\s*style="[^"]*"/, '')                  # Удаляем inline стили
    text = text.gsub(/\s*target="[^"]*"/, '')                 # Удаляем target="_blank"

    # Очищаем пробелы
    text = text.gsub(/\s+/, ' ')                              # Множественные пробелы в один
    text = text.gsub(/>\s+</, '><')                           # Удаляем пробелы между тегами

    text.strip
  end

  def build_prompt
    @language == 'ru' ? build_russian_prompt : build_ukrainian_prompt
  end

  def build_size_links
    # Генерируем HTML ссылки на размеры шин
    valid_index = 0
    @typical_sizes.filter_map do |size|
      # Парсим размер типа "215/55R17" или "215/55 R17" (с пробелом перед R)
      if size =~ /(\d+)\/(\d+)\s*R(\d+)/i
        width, height, radius = $1, $2, $3
        unless valid_tire_dimensions?(width, height, radius)
          Rails.logger.warn "Skipping invalid tire size in prompt: #{size} (w=#{width}, h=#{height}, r=#{radius})"
          next
        end
        valid_index += 1
        url = @language == 'ua' ? "/ua/shiny/w-#{width}/h-#{height}/r-#{radius}/" : "/shiny/w-#{width}/h-#{height}/r-#{radius}/"
        tires_word = @language == 'ua' ? 'шини' : 'шины'
        "#{valid_index}. <a href=\"#{url}\">#{tires_word} #{size}</a>"
      end
    end.join("\n")
  end

  def build_brand_links
    # Генерируем ссылки на бренд и бренд+размеры
    brand_url = @language == 'ua' ? "/ua/shiny/auto/#{@brand.downcase}/#{@model.downcase}/" : "/shiny/auto/#{@brand.downcase}/#{@model.downcase}/"
    tires_word = @language == 'ua' ? 'шини для' : 'шины для'
    links = []
    links << "- <a href=\"#{brand_url}\">#{tires_word} #{@brand.capitalize} #{@model.capitalize}</a>"

    # Добавляем ссылки на размеры с брендом (берём первые 2 валидных)
    valid_sizes = @typical_sizes.select do |size|
      size =~ /(\d+)\/(\d+)\s*R(\d+)/i && valid_tire_dimensions?($1, $2, $3)
    end
    valid_sizes.first(2).each do |size|
      if size =~ /(\d+)\/(\d+)\s*R(\d+)/i
        width, height, radius = $1, $2, $3
        size_url = @language == 'ua' ? "/ua/shiny/w-#{width}/h-#{height}/r-#{radius}/" : "/shiny/w-#{width}/h-#{height}/r-#{radius}/"
        links << "- <a href=\"#{size_url}\">#{tires_word.split(' ')[0]} #{size} для #{@brand.capitalize} #{@model.capitalize}</a>"
      end
    end

    links.join("\n")
  end

  def select_random_tire_brands
    # Выбираем по одному случайному бренду из каждого сегмента
    selected_brands = []

    TIRE_BRANDS_BY_SEGMENT.each do |segment, brands|
      # Фильтруем бренды, которые есть в базе данных для данного языка
      available_brands = brands.select do |brand_name|
        Brand.exists?(name: brand_name, language: @language)
      end

      # Если нет брендов в базе - используем любой из списка
      brand_to_use = available_brands.any? ? available_brands.sample : brands.sample
      selected_brands << brand_to_use
    end

    selected_brands
  end

  def build_tire_brand_links
    # Генерируем ссылки на выбранные бренды шин
    selected_brands = select_random_tire_brands

    links = selected_brands.map do |brand_name|
      # Ищем URL бренда в базе данных
      brand_record = Brand.find_by(name: brand_name, language: @language)

      if brand_record && brand_record.url.present?
        url = normalize_brand_url(brand_record.url)
        # Добавляем префикс для украинского языка если нужно
        url = "/ua#{url}" if @language == 'ua' && !url.start_with?('/ua')
        "- <a href=\"#{url}\">#{brand_name}</a>"
      else
        # Fallback: генерируем URL из названия бренда
        slug = brand_name.downcase.gsub(/\s+/, '-')
        url = @language == 'ua' ? "/ua/shiny/#{slug}/" : "/shiny/#{slug}/"
        "- <a href=\"#{url}\">#{brand_name}</a>"
      end
    end

    { brands: selected_brands, links: links.join("\n") }
  end

  # Нормализует URL бренда к формату /shiny/brand-name/
  def normalize_brand_url(url)
    return '/shiny/' if url.blank?

    # Убираем лишние пробелы
    url = url.strip

    # Если URL не начинается с / - добавляем /shiny/
    unless url.start_with?('/')
      url = "/shiny/#{url}"
    end

    # Если URL не содержит /shiny/ - добавляем
    unless url.include?('/shiny/')
      url = "/shiny#{url}"
    end

    # Убираем /ua/ если есть (добавим позже при необходимости)
    url = url.sub('/ua/', '/')

    # Добавляем / в конце если нет
    url = "#{url}/" unless url.end_with?('/')

    url
  end

  def build_russian_prompt
    wikipedia_section = if @wikipedia_info.present?
      <<~WIKI
        ИНФОРМАЦИЯ ИЗ WIKIPEDIA:
        #{@wikipedia_info}

        ИНСТРУКЦИЯ: Используй эту информацию для более точного и детального описания автомобиля в разделе "О модели" и при упоминании характеристик. Указывай годы выпуска, класс автомобиля, особенности из Wikipedia.

      WIKI
    else
      ""
    end

    # Получаем динамически выбранные бренды и их ссылки
    tire_brands_data = build_tire_brand_links
    selected_brands = tire_brands_data[:brands]
    tire_brand_links = tire_brands_data[:links]

    prompt = <<~PROMPT
      КРИТИЧЕСКИ ВАЖНО: Генерируй текст ТОЛЬКО на русском языке!

      Создай структурированный SEO-оптимизированный HTML-текст для страницы подбора шин интернет-магазина ProKoleso для автомобиля #{@brand.capitalize} #{@model.capitalize}.

      ИСХОДНЫЕ ДАННЫЕ:
      - Марка: #{@brand.capitalize}
      - Модель: #{@model.capitalize}
      #{@generation.present? ? "- Поколение: #{@generation}" : ""}
      #{@production_years.present? ? "- Годы выпуска: #{@production_years}" : ""}
      #{@body_type.present? ? "- Тип кузова: #{@body_type}" : ""}
      #{@car_class.present? ? "- Класс автомобиля: #{@car_class}" : ""}
      - Типичные размеры шин: #{@typical_sizes.join(', ')}

      #{wikipedia_section}

      ССЫЛКИ ДЛЯ ОРГАНИЧНОЙ ВСТАВКИ В ТЕКСТ:
      #{build_brand_links}

      #{build_size_links}

      ССЫЛКИ НА БРЕНДЫ ШИН (ОБЯЗАТЕЛЬНО ИСПОЛЬЗУЙ ВСЕ ТРИ):
      #{tire_brand_links}

      ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ ССЫЛОК:
      - Каждую ссылку используй ТОЧНО ОДИН РАЗ в тексте
      - Вставляй ссылки органично в соответствующий контекст
      - Используй предоставленный HTML-код ссылок БЕЗ ИЗМЕНЕНИЙ
      - НЕ СОЗДАВАЙ ВЛОЖЕННЫЕ ССЫЛКИ
      - АНКОР ссылки на типоразмер ДОЛЖЕН БЫТЬ САМИМ ТИПОРАЗМЕРОМ (например: <a href="...">215/55R17</a>)
      - ЗАПРЕЩЕНО оставлять URL в виде открытого текста - всегда оборачивай в тег <a>
      - ЗАПРЕЩЕНО создавать ссылки на текущую страницу модели #{@brand.capitalize} #{@model.capitalize} (/shiny/auto/#{@brand.downcase}/#{@model.downcase}/) - это циклическая ссылка!

      ТРЕБОВАНИЯ К ТЕКСТУ:
      1. НЕ используй <div>, классы, ID или <style> - только чистый HTML с заголовками, параграфами и списками
      2. Начни СРАЗУ с заголовка <h2>Подбор шин для #{@brand.capitalize} #{@model.capitalize}</h2>
      3. В ЗАГОЛОВКАХ НЕ используй ЗАГЛАВНЫЕ БУКВЫ (CAPS LOCK) - пиши обычным регистром: "Типичные размеры шин", а НЕ "ТИПИЧНЫЕ РАЗМЕРЫ ШИН"
      4. Используй списки (<ul> или <ol>) для перечислений
      5. Длина текста: 1500-2500 знаков (компактный формат)
      6. ОБЯЗАТЕЛЬНО органично вставь ВСЕ предоставленные ссылки в текст (каждую ссылку только ОДИН раз)
      7. Используй только объективный, технический стиль изложения. НЕ используй личные местоимения (я, мне, мой и т.д.)

      ПРАВИЛА ФОРМАТИРОВАНИЯ:
      - НЕ выделяй жирным (<strong>) текст в заголовках H2, H3, H4
      - НЕ используй вложенные теги <strong><strong></strong></strong>
      - НЕ выделяй жирным текст внутри ссылок <a>
      - НЕ дублируй информацию - каждый факт упоминай только один раз
      - ЗАПРЕЩЕНО использовать иероглифы, символы китайского, японского, корейского и других восточноазиатских языков. Используй ТОЛЬКО кириллицу и латиницу!
      - Слово "интернет-магазин" пиши ТОЛЬКО через дефис без пробелов: "интернет-магазин". ЗАПРЕЩЕНО: "интернет магазин", "интернет - магазин", "интернет+магазин", "интернет&магазин" и другие варианты!

      СТРУКТУРА ТЕКСТА (строго следуй этому порядку):

      1. <h2>Подбор шин для #{@brand.capitalize} #{@model.capitalize}</h2>

      2. Краткое вступление (2-3 предложения в теге <p>):
         - Упомяни "шины для #{@brand.capitalize} #{@model.capitalize}"
         #{@body_type.present? ? "- Укажи тип кузова: #{@body_type}" : "- Укажи тип кузова или класс автомобиля (если можешь определить)"}
         - Выдели, что это подбор по параметрам (размеру, сезону, стилю вождения)

      #{@wikipedia_info.present? ? "3. <h3>Об автомобиле #{@brand.capitalize} #{@model.capitalize}</h3>
         <p>ОБЯЗАТЕЛЬНО 300-500 символов (3-5 предложений) об автомобиле на основе Wikipedia:
         - Годы выпуска, поколения, история модели
         - Класс автомобиля, позиционирование на рынке
         - Ключевые особенности: двигатели, платформа, технологии
         - Популярность, целевая аудитория
         Используй ТОЛЬКО факты из Wikipedia. Текст должен быть информативным и полезным!</p>

      4. <h3>Типичные размеры шин для #{@brand.capitalize} #{@model.capitalize}</h3>" : "3. <h3>Типичные размеры шин для #{@brand.capitalize} #{@model.capitalize}</h3>"}
         <p>Краткое описание размерного ряда (1-2 предложения)</p>
         <ul> со списком всех предоставленных размеров с их особенностями (используй все ссылки на размеры)

      #{@wikipedia_info.present? ? "5." : "4."} <h3>Популярные бренды и их особенности</h3>
         <p>Информация о рекомендуемых производителях шин для этой модели - кратко, 2-3 предложения с упоминанием сезонности и типов шин.
         ОБЯЗАТЕЛЬНО упомяни следующие бренды и ИСПОЛЬЗУЙ предоставленные ссылки на них: #{selected_brands.join(', ')}</p>

      #{@wikipedia_info.present? ? "6." : "5."} <h3>Рекомендации по подбору шин</h3>
         <ul> или <ol> с 4-5 пунктами:
           <li>Индексы нагрузки и скорости для данной модели</li>
           <li>Выбор сезонности (лето, зима, всесезонка)</li>
           <li>Рисунок протектора под стиль вождения</li>
           <li>Рекомендуемое давление</li>
         </ul>

      #{@wikipedia_info.present? ? "7." : "6."} <h3>Преимущества ProKoleso</h3>
         <p>Краткое описание преимуществ (2-3 предложения): широкий выбор, проверенные бренды, доставка, консультация.</p>

      ЗАВЕРШЕНИЕ ТЕКСТА (БЕЗ заголовка):
      Одно краткое предложение с фразой "оформите заказ онлайн".
      Варианты формулировки (выбери ТОЧНО один из указанных):
      - "Подобрать шины на #{@brand.capitalize} #{@model.capitalize} в каталоге и оформить заказ онлайн можно на ProKoleso.ua"
      - "Выбрать и купить шины на #{@brand.capitalize} #{@model.capitalize} можно в интернет-магазине ProKoleso - оформите заказ онлайн."
      - "Подберите шины на #{@brand.capitalize} #{@model.capitalize} в каталоге ProKoleso и оформите заказ онлайн."
      ВАЖНО: Используй ТОЛЬКО указанные варианты БЕЗ изменений и дополнений. НЕ добавляй "через корзину", "достаточно", "предусмотрена консультация" и другие пояснения!

      СТИЛЬ ИЗЛОЖЕНИЯ:
      - Используй безличные конструкции: "Шины характеризуются...", "Модель отличается...", "Для #{@brand.capitalize} #{@model.capitalize} рекомендуются..."
      - Избегай местоимений "их", "них", "его", "ее"

      ВАЖНО ПО ФОРМАТУ ССЫЛОК:
      - ВСЕГДА используй формат: /shiny/w-215/h-55/r-17/
      - НЕПРАВИЛЬНО: /shiny/215/55/r17/ или /shiny/w215/h55/r-17/
      - ПРАВИЛЬНО: /shiny/w-215/h-55/r-17/
      - ЗАПРЕЩЕНО вставлять пробелы внутри URL-адресов и HTML-атрибутов. URL должен быть слитным: /shiny/w-245/h-40/r-19/, а НЕ /shiny/w 245/h 40/r 19/

      КРИТИЧЕСКИЕ ПРАВИЛА HTML И URL (НАРУШЕНИЕ = БРАК):
      1. HTML-теги пиши ТОЛЬКО латиницей: <li>, </li>, <p>, </p>, <ul>, </ul>, <h2>, <a href="...">.
         ЗАПРЕЩЕНО: <лі>, </лі>, <п>, <!--ли-->, <!--лi-->. Кириллица в именах тегов НЕДОПУСТИМА!
      2. URL-адреса пиши ТОЛЬКО латиницей и цифрами. Используй ТОЛЬКО предоставленные ссылки БЕЗ изменений.
         ЗАПРЕЩЕНО создавать свои URL с кириллицей: /шины/, /я/, /ya/, /cxины/, /в-205/, /н-55/, /р-16/.
         ПРАВИЛЬНО: /shiny/, /ua/, w-, h-, r- — только латиница!
      3. Для украинской версии сайта префикс ТОЛЬКО /ua/, НИКОГДА /ya/, /я/ или другие варианты.
      4. НЕ вставляй &nbsp; между тегами или внутри ссылок. НЕ генерируй пустые теги <p>&nbsp;</p>.
      5. НЕ СОЗДАВАЙ НОВЫЕ ССЫЛКИ — используй ТОЛЬКО те href, которые предоставлены выше. Если ссылка не предоставлена — пиши текст без ссылки.

      #{build_geographic_restrictions}

      ВАЖНО: Верни ТОЛЬКО чистый HTML-код БЕЗ <div>, БЕЗ классов, БЕЗ <style>, БЕЗ markdown блоков. Начни сразу с <h2>.
      НЕ ДОБАВЛЯЙ теги <!DOCTYPE>, <html>, <head>, <body> - ТОЛЬКО содержимое начиная с <h2> и заканчивая </p>.
    PROMPT

    prompt
  end

  def build_ukrainian_prompt
    # Перевод значений для украинского языка
    body_type_ua = translate_body_type(@body_type) if @body_type.present?

    wikipedia_section = if @wikipedia_info.present?
      <<~WIKI
        ІНФОРМАЦІЯ З WIKIPEDIA:
        #{@wikipedia_info}

        ІНСТРУКЦІЯ: Використовуй цю інформацію для більш точного та детального опису автомобіля в розділі "Про модель" та при згадці характеристик. Вказуй роки випуску, клас автомобіля, особливості з Wikipedia.

      WIKI
    else
      ""
    end

    # Получаем динамически выбранные бренды и их ссылки
    tire_brands_data = build_tire_brand_links
    selected_brands = tire_brands_data[:brands]
    tire_brand_links = tire_brands_data[:links]

    prompt = <<~PROMPT
      КРИТИЧНО ВАЖЛИВО: Генеруй текст ТІЛЬКИ українською мовою!

      Створи структурований SEO-оптимізований HTML-текст для сторінки підбору шин інтернет-магазину ProKoleso для автомобіля #{@brand.capitalize} #{@model.capitalize}.

      ВИХІДНІ ДАНІ:
      - Марка: #{@brand.capitalize}
      - Модель: #{@model.capitalize}
      #{@generation.present? ? "- Покоління: #{@generation}" : ""}
      #{@production_years.present? ? "- Роки випуску: #{@production_years}" : ""}
      #{body_type_ua.present? ? "- Тип кузова: #{body_type_ua}" : ""}
      #{@car_class.present? ? "- Клас автомобіля: #{@car_class}" : ""}
      - Типові розміри шин: #{@typical_sizes.join(', ')}

      #{wikipedia_section}

      ПОСИЛАННЯ ДЛЯ ОРГАНІЧНОЇ ВСТАВКИ В ТЕКСТ:
      #{build_brand_links}

      #{build_size_links}

      ПОСИЛАННЯ НА БРЕНДИ ШИН (ОБОВ'ЯЗКОВО ВИКОРИСТАЙ УСІ ТРИ):
      #{tire_brand_links}

      ІНСТРУКЦІЯ З ВИКОРИСТАННЯ ПОСИЛАНЬ:
      - Кожне посилання використовуй ТОЧНО ОДИН РАЗ в тексті
      - Вставляй посилання органічно у відповідний контекст
      - Використовуй наданий HTML-код посилань БЕЗ ЗМІН
      - НЕ СТВОРЮЙ ВКЛАДЕНІ ПОСИЛАННЯ
      - АНКОР посилання на типорозмір ПОВИНЕН БУТИ САМИМ ТИПОРОЗМІРОМ (наприклад: <a href="...">215/55R17</a>)
      - ЗАБОРОНЕНО залишати URL у вигляді відкритого тексту - завжди обгортай в тег <a>
      - ЗАБОРОНЕНО створювати посилання на поточну сторінку моделі #{@brand.capitalize} #{@model.capitalize} (/shiny/auto/#{@brand.downcase}/#{@model.downcase}/) - це циклічне посилання!

      ВИМОГИ ДО ТЕКСТУ:
      1. НЕ використовуй <div>, класи, ID або <style> - тільки чистий HTML із заголовками, параграфами та списками
      2. Почни ОДРАЗУ з заголовка <h2>Підбір шин для #{@brand.capitalize} #{@model.capitalize}</h2>
      3. В ЗАГОЛОВКАХ НЕ використовуй ВЕЛИКІ ЛІТЕРИ (CAPS LOCK) - пиши звичайним регістром: "Типові розміри шин", а НЕ "ТИПОВІ РОЗМІРИ ШИН"
      4. Використовуй списки (<ul> або <ol>) для переліків
      5. Довжина тексту: 1500-2500 знаків (компактний формат)
      6. ОБОВ'ЯЗКОВО органічно встав ВСІ надані посилання в текст (кожне посилання тільки ОДИН раз)
      7. Використовуй тільки об'єктивний, технічний стиль викладу. НЕ використовуй особові займенники (я, мені, мій тощо)

      ПРАВИЛА ФОРМАТУВАННЯ:
      - НЕ виділяй жирним (<strong>) текст в заголовках H2, H3, H4
      - НЕ використовуй вкладені теги <strong><strong></strong></strong>
      - НЕ виділяй жирним текст всередині посилань <a>
      - НЕ дублюй інформацію - кожен факт згадуй тільки один раз
      - ЗАБОРОНЕНО використовувати ієрогліфи, символи китайської, японської, корейської та інших східноазіатських мов. Використовуй ТІЛЬКИ кирилицю та латиницю!
      - Слово "інтернет-магазин" пиши ТІЛЬКИ через дефіс без пробілів: "інтернет-магазин". ЗАБОРОНЕНО: "інтернет магазин", "інтернет - магазин", "інтернет+магазин", "інтернет&магазин" та будь-які інші варіанти!

      СТРУКТУРА ТЕКСТУ (строго дотримуйся цього порядку):

      1. <h2>Підбір шин для #{@brand.capitalize} #{@model.capitalize}</h2>

      2. Короткий вступ (2-3 речення в тезі <p>):
         - Згадай "шини для #{@brand.capitalize} #{@model.capitalize}"
         #{body_type_ua.present? ? "- Вкажи тип кузова: #{body_type_ua}" : "- Вкажи тип кузова або клас автомобіля (якщо можеш визначити)"}
         - Виділи, що це підбір за параметрами (розміром, сезоном, стилем водіння)

      #{@wikipedia_info.present? ? "3. <h3>Про автомобіль #{@brand.capitalize} #{@model.capitalize}</h3>
         <p>ОБОВ'ЯЗКОВО 300-500 символів (3-5 речень) про автомобіль на основі Wikipedia:
         - Роки випуску, покоління, історія моделі
         - Клас автомобіля, позиціонування на ринку
         - Ключові особливості: двигуни, платформа, технології
         - Популярність, цільова аудиторія
         Використовуй ТІЛЬКИ факти з Wikipedia. Текст має бути інформативним та корисним!</p>

      4. <h3>Типові розміри шин для #{@brand.capitalize} #{@model.capitalize}</h3>" : "3. <h3>Типові розміри шин для #{@brand.capitalize} #{@model.capitalize}</h3>"}
         <p>Короткий опис розмірного ряду (1-2 речення)</p>
         <ul> зі списком усіх наданих розмірів та їхніх особливостей (використовуй усі посилання на розміри)

      #{@wikipedia_info.present? ? "5." : "4."} <h3>Популярні бренди та їхні особливості</h3>
         <p>Інформація про рекомендовані виробники шин для цієї моделі - коротко, 2-3 речення з згадкою сезонності та типів шин.
         ОБОВ'ЯЗКОВО згадай наступні бренди та ВИКОРИСТАЙ надані посилання на них: #{selected_brands.join(', ')}</p>

      #{@wikipedia_info.present? ? "6." : "5."} <h3>Рекомендації щодо підбору шин</h3>
         <ul> або <ol> з 4-5 пунктами:
           <li>Індекси навантаження та швидкості для даної моделі</li>
           <li>Вибір сезонності (літо, зима, всесезонка)</li>
           <li>Малюнок протектора під стиль водіння</li>
           <li>Рекомендований тиск</li>
         </ul>

      #{@wikipedia_info.present? ? "7." : "6."} <h3>Переваги ProKoleso</h3>
         <p>Короткий опис переваг (2-3 речення): широкий вибір, перевірені бренди, доставка, консультація.</p>

      ЗАВЕРШЕННЯ ТЕКСТУ (БЕЗ заголовка):
      Одне коротке речення з фразою "оформіть замовлення онлайн".
      Варіанти формулювання (обери ТОЧНО один з наведених):
      - "Підібрати шини на #{@brand.capitalize} #{@model.capitalize} в каталозі та оформити замовлення онлайн можна на ProKoleso.ua"
      - "Вибрати та купити шини на #{@brand.capitalize} #{@model.capitalize} можна в інтернет-магазині ProKoleso - оформіть замовлення онлайн."
      - "Підберіть шини на #{@brand.capitalize} #{@model.capitalize} в каталозі ProKoleso та оформіть замовлення онлайн."
      ВАЖЛИВО: Використовуй ЛИШЕ наведені варіанти БЕЗ змін і доповнень. НЕ додавай "через кошик", "достатньо", "передбачена консультація" та інші пояснення!

      СТИЛЬ ВИКЛАДУ:
      - Використовуй безособові конструкції: "Шини характеризуються...", "Модель відрізняється...", "Для #{@brand.capitalize} #{@model.capitalize} рекомендуються..."
      - Уникай займенників "їх", "них", "його", "її"

      ВАЖЛИВО ПО ФОРМАТУ ПОСИЛАНЬ:
      - ЗАВЖДИ використовуй формат: /shiny/w-215/h-55/r-17/
      - НЕПРАВИЛЬНО: /shiny/215/55/r17/ або /shiny/w215/h55/r-17/
      - ПРАВИЛЬНО: /shiny/w-215/h-55/r-17/
      - ЗАБОРОНЕНО вставляти пробіли всередині URL-адрес та HTML-атрибутів. URL має бути злитним: /shiny/w-245/h-40/r-19/, а НЕ /shiny/w 245/h 40/r 19/

      КРИТИЧНІ ПРАВИЛА HTML ТА URL (ПОРУШЕННЯ = БРАК):
      1. HTML-теги пиши ТІЛЬКИ латиницею: <li>, </li>, <p>, </p>, <ul>, </ul>, <h2>, <a href="...">.
         ЗАБОРОНЕНО: <лі>, </лі>, <п>, <!--ли-->, <!--лi-->. Кирилиця в іменах тегів НЕПРИПУСТИМА!
      2. URL-адреси пиши ТІЛЬКИ латиницею та цифрами. Використовуй ТІЛЬКИ надані посилання БЕЗ змін.
         ЗАБОРОНЕНО створювати свої URL з кирилицею: /шини/, /я/, /ya/, /cxини/, /в-205/, /н-55/, /р-16/.
         ПРАВИЛЬНО: /shiny/, /ua/, w-, h-, r- — тільки латиниця!
      3. Для української версії сайту префікс ТІЛЬКИ /ua/, НІКОЛИ /ya/, /я/ або інші варіанти.
      4. НЕ вставляй &nbsp; між тегами або всередині посилань. НЕ генеруй порожні теги <p>&nbsp;</p>.
      5. НЕ СТВОРЮЙ НОВІ ПОСИЛАННЯ — використовуй ТІЛЬКИ ті href, які надані вище. Якщо посилання не надано — пиши текст без посилання.

      #{build_geographic_restrictions}

      ВАЖЛИВО: Поверни ТІЛЬКИ чистий HTML-код БЕЗ <div>, БЕЗ класів, БЕЗ <style>, БЕЗ markdown блоків. Почни одразу з <h2>.
      НЕ ДОДАВАЙ теги <!DOCTYPE>, <html>, <head>, <body> - ТІЛЬКИ вміст починаючи з <h2> і закінчуючи </p>.
    PROMPT

    prompt
  end

  def translate_body_type(body_type)
    translations = {
      'седан' => 'седан',
      'хэтчбек' => 'хетчбек',
      'кроссовер' => 'кросовер',
      'внедорожник' => 'позашляховик',
      'универсал' => 'універсал',
      'купе' => 'купе',
      'минивэн' => 'мінівен',
      'пикап' => 'пікап'
    }
    translations[body_type.downcase] || body_type
  end

  # Автоматически завершает обрезанный текст
  def complete_truncated_text(truncated_text, original_max_tokens)
    Rails.logger.info "Attempting to complete truncated car SEO text..."

    # Определяем, что именно отсутствует в тексте
    missing_elements = analyze_missing_elements(truncated_text)

    completion_prompt = build_completion_prompt(truncated_text, missing_elements)

    # Используем меньше токенов для дописывания (500-800 достаточно для завершения)
    response = ContentWriter.new.write_seo_text(completion_prompt, 800)

    if response && response['choices'] && response['choices'][0]
      completion = response['choices'][0]['message']['content'].strip

      # Объединяем исходный текст с дописанным
      merge_texts(truncated_text, completion)
    else
      nil
    end
  rescue => e
    Rails.logger.error "Error completing car SEO text: #{e.message}"
    nil
  end

  # Анализирует, каких элементов не хватает в тексте
  def analyze_missing_elements(text)
    missing = []

    # Проверяем наличие CTA фраз
    cta_phrases = @language == 'ua' ?
      ['оформіть замовлення онлайн', 'замовити онлайн'] :
      ['оформите заказ онлайн', 'заказать онлайн']

    has_cta = cta_phrases.any? { |phrase| text.include?(phrase) }
    missing << :cta unless has_cta

    # Проверяем наличие закрывающего </p>
    missing << :closing_tag unless text.strip.end_with?('</p>')

    # Проверяем наличие последнего параграфа с призывом к действию
    last_p_match = text.match(/<p>([^<]*(?:<[^\/][^>]*>[^<]*<\/[^>]+>)*[^<]*)<\/p>\s*$/i)
    if last_p_match
      last_paragraph = last_p_match[1]
      buy_phrases = @language == 'ua' ?
        ['купити шини', 'купити резину'] :
        ['купить шины', 'купить резину']
      has_buy_phrase = buy_phrases.any? { |phrase| last_paragraph.downcase.include?(phrase) }
      missing << :buy_phrase unless has_buy_phrase
    else
      missing << :final_paragraph
    end

    missing
  end

  # Строит промпт для завершения текста
  def build_completion_prompt(truncated_text, missing_elements)
    language_instruction = @language == 'ua' ?
      'КРИТИЧНО ВАЖЛИВО: Пиши ТІЛЬКИ українською мовою!' :
      'КРИТИЧЕСКИ ВАЖНО: Пиши ТОЛЬКО на русском языке!'

    task_description = if @language == 'ua'
      "Тобі надано незавершений SEO-текст про шини для #{@brand.capitalize} #{@model.capitalize}."
    else
      "Тебе предоставлен незавершенный SEO-текст о шинах для #{@brand.capitalize} #{@model.capitalize}."
    end

    requirements = []
    if missing_elements.include?(:cta) || missing_elements.include?(:buy_phrase) || missing_elements.include?(:final_paragraph)
      requirements << if @language == 'ua'
        "Додай заключний параграф <p> з фразами 'Купити шини на #{@brand.capitalize} #{@model.capitalize}' та 'оформіть замовлення онлайн'"
      else
        "Добавь заключительный параграф <p> с фразами 'Купить шины на #{@brand.capitalize} #{@model.capitalize}' и 'оформите заказ онлайн'"
      end
    end

    if missing_elements.include?(:closing_tag)
      requirements << (@language == 'ua' ?
        "Закрий всі незакриті HTML-теги" :
        "Закрой все незакрытые HTML-теги")
    end

    <<~PROMPT
      #{language_instruction}

      #{task_description}

      НЕЗАВЕРШЕННЫЙ ТЕКСТ:
      #{truncated_text}

      ЗАДАНИЕ:
      #{requirements.join("\n")}

      ВАЖНО:
      - #{@language == 'ua' ? 'Поверни ТІЛЬКИ текст для доповнення (продовження останнього речення + заключний параграф)' : 'Верни ТОЛЬКО текст для дополнения (продолжение последнего предложения + заключительный параграф)'}
      - #{@language == 'ua' ? 'НЕ дублюй існуючий текст' : 'НЕ дублируй существующий текст'}
      - #{@language == 'ua' ? 'Використовуй тільки чистий HTML без <div>, класів, стилів' : 'Используй только чистый HTML без <div>, классов, стилей'}
      - #{@language == 'ua' ? 'Текст має логічно продовжувати попередній' : 'Текст должен логично продолжать предыдущий'}
      - #{@language == 'ua' ? 'Обсяг: 100-200 слів' : 'Объем: 100-200 слов'}

      СТИЛЬ ВИКЛАДУ:
      - #{@language == 'ua' ? 'КАТЕГОРИЧНО ЗАБОРОНЕНО використовувати особові займенники та особисті оцінки' : 'КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО использовать личные местоимения и личные оценки'}
      - #{@language == 'ua' ? 'НЕ використовуй: "я", "мені", "мій", "особисто переконався", "раджу", "можу підтвердити", "як клієнт"' : 'НЕ используй: "я", "мне", "мой", "лично убедился", "советую", "могу подтвердить", "как клиент"'}
      - #{@language == 'ua' ? 'Використовуй ТІЛЬКИ нейтральний інформаційний стиль' : 'Используй ТОЛЬКО нейтральный информационный стиль'}
      - #{@language == 'ua' ? 'Безособові конструкції: "Шини забезпечують", "Модель характеризується", "Рекомендується", "Доступно до замовлення"' : 'Безличные конструкции: "Шины обеспечивают", "Модель характеризуется", "Рекомендуется", "Доступно к заказу"'}
      - #{@language == 'ua' ? 'Це текст для карточки товару в інтернет-магазині, а не особистий відгук!' : 'Это текст для карточки товара в интернет-магазине, а не личный отзыв!'}
    PROMPT
  end

  # Объединяет исходный текст с дописанным
  def merge_texts(original, completion)
    # Очищаем completion от возможных markdown блоков
    completion = completion.gsub(/```html\s*/, '').gsub(/```\s*$/, '').strip

    # Удаляем из completion возможные начальные теги документа
    completion = completion.gsub(/^<!DOCTYPE[^>]*>/i, '')
                          .gsub(/^<html[^>]*>/i, '')
                          .gsub(/^<body[^>]*>/i, '')
                          .strip

    # Проверяем, заканчивается ли оригинальный текст незакрытым тегом
    original_cleaned = original.dup

    # Если текст обрезан посреди слова или тега - находим последний полный тег
    if original_cleaned =~ /<[^>]*$/
      # Удаляем незакрытый тег в конце
      original_cleaned = original_cleaned.sub(/<[^>]*$/, '')
    end

    # Удаляем неполный CTA параграф из оригинала (если есть)
    original_cleaned = remove_incomplete_cta(original_cleaned)

    # Находим последний закрывающий тег
    last_closing_tag = original_cleaned.rindex(/<\/[^>]+>/)

    if last_closing_tag
      # Берем текст до последнего закрывающего тега + сам тег
      tag_end = original_cleaned.index('>', last_closing_tag) + 1
      original_cleaned = original_cleaned[0...tag_end]
    end

    # Удаляем дублирование: проверяем, не начинается ли completion с конца original
    completion = remove_duplicate_text(original_cleaned, completion)

    # Объединяем тексты
    merged = original_cleaned.strip
    merged += ' ' unless merged.end_with?(' ', '>')
    merged += completion

    # Финальная очистка
    clean_html_text(merged)
  end

  # Удаляет неполный CTA параграф из конца текста
  def remove_incomplete_cta(text)
    # Паттерны для поиска начала CTA фраз
    cta_patterns = @language == 'ua' ?
      ['підібрати шини', 'вибрати та купити', 'підберіть шини', 'купити шини'] :
      ['подобрать шины', 'выбрать и купить', 'подберите шины', 'купить шины']

    cta_complete_phrases = @language == 'ua' ?
      ['оформіть замовлення онлайн', 'замовити онлайн'] :
      ['оформите заказ онлайн', 'заказать онлайн']

    # Находим ВСЕ параграфы
    paragraphs = text.scan(/<p>([^<]*(?:<[^\/][^>]*>[^<]*<\/[^>]+>)*[^<]*)<\/p>/i)

    return text if paragraphs.empty?

    # Проверяем последние 2-3 параграфа на наличие CTA
    cta_paragraphs_count = 0
    paragraphs.reverse.take(3).each do |para|
      para_text = para[0].downcase
      has_cta = cta_patterns.any? { |pattern| para_text.include?(pattern) }
      break unless has_cta
      cta_paragraphs_count += 1
    end

    # Если найдено 2 или более CTA параграфов подряд - удаляем ВСЕ кроме одного
    if cta_paragraphs_count >= 2
      Rails.logger.warn "Found #{cta_paragraphs_count} consecutive CTA paragraphs - removing extras"

      # Удаляем последние (cta_paragraphs_count - 1) параграфов
      text_cleaned = text.dup
      (cta_paragraphs_count - 1).times do
        text_cleaned = text_cleaned.sub(/<p>[^<]*(?:<[^\/][^>]*>[^<]*<\/[^>]+>)*[^<]*<\/p>\s*$/i, '')
      end

      Rails.logger.info "Removed #{cta_paragraphs_count - 1} duplicate CTA paragraphs"
      return text_cleaned.strip
    end

    # Проверяем последний параграф на неполный CTA
    last_p_match = text.match(/<p>([^<]*(?:<[^\/][^>]*>[^<]*<\/[^>]+>)*[^<]*)<\/p>\s*$/i)

    if last_p_match
      last_paragraph = last_p_match[1].downcase

      # Если последний параграф содержит начало CTA, но не содержит полную CTA фразу
      has_cta_start = cta_patterns.any? { |pattern| last_paragraph.include?(pattern) }
      has_cta_complete = cta_complete_phrases.any? { |phrase| last_paragraph.include?(phrase) }

      # Если есть начало CTA, но нет завершения - удаляем весь параграф
      if has_cta_start && !has_cta_complete
        text_without_last_p = text.sub(/<p>[^<]*(?:<[^\/][^>]*>[^<]*<\/[^>]+>)*[^<]*<\/p>\s*$/i, '')
        Rails.logger.info "Removed incomplete CTA paragraph from original car SEO text"
        return text_without_last_p.strip
      end
    end

    text
  end

  # Удаляет дублирующийся текст из начала completion
  def remove_duplicate_text(original, completion)
    # Извлекаем текст без HTML тегов для сравнения
    original_text = original.gsub(/<[^>]+>/, ' ').gsub(/\s+/, ' ').strip
    completion_text = completion.gsub(/<[^>]+>/, ' ').gsub(/\s+/, ' ').strip

    return completion if original_text.empty? || completion_text.empty?

    # Берем последние N слов из оригинала (где N от 3 до 15)
    original_words = original_text.split(/\s+/)
    completion_words = completion_text.split(/\s+/)

    # Проверяем совпадение последних слов оригинала с первыми словами дополнения
    max_check = [original_words.length, 15].min

    (3..max_check).reverse_each do |n|
      last_n_words = original_words.last(n).join(' ')

      # Проверяем, начинается ли completion с этих слов
      if completion_text.start_with?(last_n_words)
        # Находим позицию после дублирующейся части
        duplicate_end = completion_text.index(last_n_words) + last_n_words.length

        # Удаляем дублирующуюся часть из completion
        cleaned_completion = completion_text[duplicate_end..-1].strip

        Rails.logger.info "Removed duplicate text: '#{last_n_words}'"

        # Восстанавливаем HTML структуру если она была
        # Если completion начинался с <p>, сохраняем это
        if completion.strip.start_with?('<p>')
          return "<p>#{cleaned_completion}"
        else
          return cleaned_completion
        end
      end
    end

    completion
  end

  # Балансирует HTML-теги: добавляет недостающие закрывающие теги
  # LLM иногда забывает закрыть <p>, <li>, <ul> и т.д.
  def balance_html_tags(text)
    return text if text.blank?

    # p обрабатывается ПОСЛЕДНИМ, чтобы </p> был в самом конце текста
    # (иначе ending check добавит лишний </p>)
    tags_to_balance = ['h2', 'h3', 'h4', 'ul', 'ol', 'li', 'p']

    tags_to_balance.each do |tag|
      opening_count = text.scan(/<#{tag}(?:\s[^>]*)?>/).count
      closing_count = text.scan(/<\/#{tag}>/).count

      if opening_count > closing_count
        missing = opening_count - closing_count
        Rails.logger.info "Balanced HTML: added #{missing} missing </#{tag}> tag(s)"
        # Для не-p тегов: вставляем ПЕРЕД последним </p>, чтобы сохранить </p> в конце
        # (требование text_complete? — текст должен заканчиваться на </p>)
        if tag != 'p' && text.strip.end_with?('</p>')
          insertion = "</#{tag}>" * missing
          text = text.sub(/<\/p>(\s*)\z/, "#{insertion}</p>\\1")
        else
          missing.times { text += "</#{tag}>" }
        end
      elsif closing_count > opening_count
        excess = closing_count - opening_count
        Rails.logger.info "Balanced HTML: removed #{excess} extra </#{tag}> tag(s)"
        # Умное удаление: отслеживаем глубину вложенности, удаляем только
        # "осиротевшие" закрывающие теги (те, у которых нет пары)
        depth = 0
        removed = 0
        text = text.gsub(/<(\/?)#{tag}(?:\s[^>]*)?>/) do |match|
          if $1 == '/'
            if depth <= 0 && removed < excess
              removed += 1
              '' # Удаляем осиротевший закрывающий тег
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

  # Декодирует HTML-entities, формирующие теги
  # &lt;а hreеf=&quot;url&quot;&gt; → <а hreеf="url">
  # Также декодирует осиротевшие &gt; (безопасно в контексте HTML)
  def decode_html_entity_tags(text)
    return text if text.blank?

    # Декодируем &lt;...&gt; последовательности, похожие на теги
    text = text.gsub(/&lt;(.*?)&gt;/) do
      inner = $1.strip
      # Только если содержимое похоже на тег (начинается с буквы или /, НЕ цифры)
      if inner.match?(/\A\/?[a-zA-Zа-яА-ЯіІїЇєЄґҐ]/)
        decoded = inner.gsub('&quot;', '"').gsub('&amp;', '&').gsub('&apos;', "'")
        "<#{decoded}>"
      else
        "&lt;#{$1}&gt;" # Оставляем как есть
      end
    end

    # Декодируем осиротевшие entities (в SEO-тексте не должно быть entity-кодированных скобок)
    text = text.gsub('&gt;', '>')
    text.gsub('&lt;', '<')
  end

  # Нормализует кириллические гомоглифы в HTML-тегах
  # Кириллические символы, визуально идентичные латинским, заменяются на латинские
  # <а hreеf="..."> → <a href="...">, </а> → </a>
  CYRILLIC_HOMOGLYPHS = {
    'а' => 'a', 'е' => 'e', 'о' => 'o', 'р' => 'p', 'с' => 'c',
    'х' => 'x', 'у' => 'y', 'і' => 'i',
    'А' => 'A', 'В' => 'B', 'Е' => 'E', 'К' => 'K', 'М' => 'M',
    'Н' => 'H', 'О' => 'O', 'Р' => 'P', 'С' => 'C', 'Т' => 'T', 'Х' => 'X'
  }.freeze
  CYRILLIC_HOMOGLYPH_PATTERN = /[#{CYRILLIC_HOMOGLYPHS.keys.join}]/

  # Заменяет кириллические имена тегов на латинские эквиваленты
  # <п> → <p>, </п> → </p>, <ли> → <li>, </ли> → </li>
  # <—ли—> → </li>, <—п-> → </p> (LLM использует тире вместо угловых скобок)
  CYRILLIC_TAG_MAP = {
    'п' => 'p', 'р' => 'p',
    'ли' => 'li', 'лі' => 'li',
    'ул' => 'ul',
    'ол' => 'ol',
  }.freeze

  def fix_cyrillic_tag_names(text)
    return text if text.blank?

    cyrillic_names = CYRILLIC_TAG_MAP.keys.join('|')

    # <п>, </п>, <ли>, </ли> — кириллические теги в угловых скобках
    text = text.gsub(/<\s*(\/?)\s*(#{cyrillic_names})\s*>/i) do
      slash = $1
      name = CYRILLIC_TAG_MAP[$2.downcase] || $2
      "<#{slash}#{name}>"
    end

    # <—ли—>, <—п->, <-ли->, <—п—> — тире вместо / (закрывающий тег)
    text = text.gsub(/<[—–-]\s*(#{cyrillic_names})\s*[—–-]>/i) do
      name = CYRILLIC_TAG_MAP[$1.downcase] || $1
      "</#{name}>"
    end

    text
  end

  def fix_cyrillic_in_html_tags(text)
    return text if text.blank?

    text.gsub(/<[^>]+>/) do |tag|
      original = tag
      fixed = tag.gsub(CYRILLIC_HOMOGLYPH_PATTERN) { |c| CYRILLIC_HOMOGLYPHS[c] || c }
      # Исправляем имя атрибута href: хреф/xpeф/hreef → href
      # LLM пишет href кириллицей фонетически (хреф) или гомоглифами (xpeф)
      fixed = fixed.gsub(/[хhx][рrp][еe]+[фf]/i, 'href')
      if fixed != original
        Rails.logger.info "Fixed Cyrillic homoglyphs in tag: #{original[0..60]} → #{fixed[0..60]}"
      end
      fixed
    end
  end

  # Нормализует URL-пути в href-атрибутах
  # - Убирает двойные слеши (кроме ://)
  # - Исправляет кириллические варианты /shiny/ (shiиy, shiпy, шины, cxины и т.д.)
  # - Заменяет /ya/ на /ua/
  # - Исправляет кириллические параметры: в- → w-, н- → h-, р- → r-
  # - Удаляет ссылки с полностью кириллическими brand-слагами
  def fix_cyrillic_in_urls(text)
    return text if text.blank?

    text.gsub(/<a\s+href="([^"]*)"[^>]*>(.*?)<\/a>/im) do |match|
      href = $1
      anchor = $2
      fixed = href.dup

      # Убираем двойные слеши (кроме ://)
      fixed = fixed.gsub(/(?<!:)\/{2,}/, '/')

      # Заменяем /ya/ на /ua/ (LLM путает украинский префикс)
      fixed = fixed.gsub(/\/ya(?=\/)/i, '/ua')
      fixed = fixed.gsub(/\/я(?=\/)/i, '/ua')

      # Нормализуем /shiny/ (различные LLM-опечатки с кириллицей: /shiиy/, /shiпy/)
      fixed = fixed.gsub(/\/sh[a-zA-Zа-яА-ЯіІїЇєЄґҐ]{1,4}y(?=\/)/i, '/shiny')

      # Полностью кириллические варианты "шины"/"шини" → /shiny/
      fixed = fixed.gsub(/\/(?:шин[иыі]|cxин[иыі])(?=\/)/i, '/shiny')

      # Кириллические параметры размеров: в-205 → w-205, н-55 → h-55, р-16 → r-16
      fixed = fixed.gsub(/\/[вВ][-‐‑–—](\d)/, '/w-\1')
      fixed = fixed.gsub(/\/[нН][-‐‑–—](\d)/, '/h-\1')
      fixed = fixed.gsub(/\/[рР][-‐‑–—](\d)/, '/r-\1')

      # Нормализуем Unicode-дефисы в URL (‐ ‑ – — → -)
      fixed = fixed.gsub(/[‐‑–—]/, '-')

      # Исправляем дубли /shiny/shiny → /shiny/ и /shiny/shiny-brand/ → /shiny/brand/
      fixed = fixed.gsub(/\/shiny\/shiny-/, '/shiny/')
      fixed = fixed.gsub(/\/shiny\/shiny\//, '/shiny/')

      # Исправляем кириллические сезоны в URL
      fixed = fixed.gsub(/\/(?:зимов[іі]|зимн[іиіе]{1,2})(?=\/)/i, '/zimnie')
      fixed = fixed.gsub(/\/(?:літн[іі]|летн[іиіе]{1,2})(?=\/)/i, '/letnie')
      fixed = fixed.gsub(/\/всесезонн[іиіе]{1,2}(?=\/)/i, '/vsesezonie')

      # Проверяем: если после всех фиксов в URL остались кириллические символы — удаляем ссылку, оставляем анкор
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

  # Восстанавливает сломанные <a> теги от DeepSeek
  # DeepSeek иногда разбивает href на отдельные символы-атрибуты:
  # <a e="" f="URL" h="" r=""> → <a href="URL">
  # <a ef="URL" hr=""> → <a href="URL">
  # Любой <a ...> без href= но с атрибутом, содержащим "/" — восстанавливаем
  def fix_broken_a_tags(text)
    return text if text.blank?

    text.gsub(/<a\s+([^>]*?)>/i) do |match|
      attrs = $1.strip
      # Пропускаем нормальные теги с href=
      next match if attrs.match?(/\bhref\s*=/i)

      # Ищем URL среди значений атрибутов (самое длинное значение с /)
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

  # Комплексное исправление пробелов во ВСЕХ href="..." значениях
  # URL-адреса никогда не должны содержать пробелов
  # Заменяет fix_spaces_in_tire_urls — покрывает все случаи, а не только w/h/r
  def fix_all_href_spaces(text)
    return text if text.blank?

    text.gsub(/href="([^"]*)"/) do |match|
      href = $1
      original_href = href.dup

      # 1. Убираем пробелы вокруг слешей: / ua / shiny / → /ua/shiny/
      href = href.gsub(/\s*\/\s*/, '/')

      # 2. Исправляем паттерны типоразмеров: w 245 или w245 → w-245 (буква + цифры без дефиса)
      href = href.gsub(/([whr])\s+(\d+)/, '\1-\2')
      href = href.gsub(/\/([whr])(\d+)(?=\/)/, '/\1-\2')

      # 3. Убираем все оставшиеся пробелы из URL
      href = href.gsub(/\s+/, '')

      if href != original_href
        Rails.logger.info "Fixed spaces in href: #{original_href} -> #{href}"
      end
      "href=\"#{href}\""
    end
  end

  # Обнаруживает и удаляет абзацы с посимвольным выводом LLM (DeepSeek issue)
  # Если >50% слов в абзаце — одиночные символы, абзац считается "рассыпанным" и удаляется
  # Также обнаруживает частично "рассыпанный" текст по низкой средней длине слов
  # Это позволяет completion-механизму добавить нормальный текст вместо мусора
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
          # Пробуем починить: склеиваем последовательности из 3+ одиночных кириллических символов
          fixed_content = content.gsub(/(?<=[а-яА-ЯіІїЇєЄґҐ])\s+(?=[а-яА-ЯіІїЇєЄґҐ]\s+[а-яА-ЯіІїЇєЄґҐ](?:\s|$))/) { '' }
          # Дополнительная склейка: два одиночных кириллических символа подряд
          fixed_content = fixed_content.gsub(/\b([а-яА-ЯіІїЇєЄґҐ])\s+([а-яА-ЯіІїЇєЄґҐ])\b/, '\1\2')

          if fixed_content != content
            Rails.logger.info "Repaired spaced-out text in paragraph: #{content[0..60]} → #{fixed_content[0..60]}"
          end

          # Проверяем среднюю длину слов после починки (частично рассыпанный текст)
          repaired_words = fixed_content.split(/\s+/)
          if repaired_words.length > 15
            avg_length = repaired_words.sum(&:length).to_f / repaired_words.length
            if avg_length < 3.0
              Rails.logger.warn "Removed paragraph with abnormally low avg word length (#{avg_length.round(1)}): #{fixed_content[0..80]}..."
              next ''
            end
          end

          if fixed_content != content
            match.sub(content, fixed_content)
          else
            match
          end
        end
      else
        match
      end
    end
  end

  # Нормализует написание "інтернет-магазин" / "интернет-магазин"
  # Исправляет: інтернет1магазин, інтернет+магазин, інтернет - магазин, інтернет&магазин, інтернет магазин
  def fix_internet_magazin(text)
    return text if text.blank?

    # Украинский: інтернет-магазин (все варианты разделителей)
    text = text.gsub(/інтернет\s*[1+&\s-]+\s*магазин/i, 'інтернет-магазин')

    # Русский: интернет-магазин (все варианты разделителей)
    text = text.gsub(/интернет\s*[1+&\s-]+\s*магазин/i, 'интернет-магазин')

    text
  end

  # Удаляет иероглифы и символы восточноазиатских языков (китайский, японский, корейский)
  def remove_asian_characters(text)
    # Паттерн для китайских, японских и корейских символов:
    # \p{Han} - китайские иероглифы (CJK Unified Ideographs)
    # \p{Hiragana} - японская хирагана
    # \p{Katakana} - японская катакана
    # \p{Hangul} - корейские символы
    asian_pattern = /[\p{Han}\p{Hiragana}\p{Katakana}\p{Hangul}]+/

    if text.match?(asian_pattern)
      Rails.logger.warn "Found Asian characters in generated car SEO text, removing them..."
      # Удаляем иероглифы
      text = text.gsub(asian_pattern, '')
      # Убираем двойные пробелы, которые могли образоваться
      text = text.gsub(/\s{2,}/, ' ')
      Rails.logger.info "Asian characters removed successfully"
    end

    text
  end

  # Удаляет циклические ссылки на текущую модель автомобиля
  # Например: /shiny/auto/acura/cl-type-s/ или /shiny/auto/acura/cl type-s/ (с пробелами)
  def remove_self_referencing_links(text)
    return text if text.blank?
    return text if @brand.blank? || @model.blank?

    # Нормализуем brand и model для сравнения (lowercase, убираем спецсимволы)
    brand_normalized = @brand.downcase.gsub(/[^a-z0-9]/, '[-\\s]?')
    model_normalized = @model.downcase.gsub(/[^a-z0-9]/, '[-\\s]?')

    # Паттерн для ссылок на /shiny/auto/brand/model/ с любыми вариациями
    # Учитываем пробелы, дефисы и их комбинации в URL
    self_link_pattern = %r{<a\s+href="[^"]*\/shiny\/auto\/#{brand_normalized}\/#{model_normalized}\/?[^"]*"[^>]*>([^<]*)<\/a>}i

    text.gsub(self_link_pattern) do |match|
      link_text = $1
      Rails.logger.info "Removed self-referencing link to #{@brand}/#{@model}, keeping text: #{link_text}"
      link_text
    end
  end

  # Валидирует анкоры ссылок на типоразмеры
  # Анкор должен содержать типоразмер (например "215/55R17" или "215/55 R17")
  # Если анкор не содержит размер - удаляем ссылку, оставляем текст
  def validate_tire_link_anchors(text)
    return text if text.blank?

    # Паттерн для ссылок на типоразмеры (w-XXX/h-XX/r-XX)
    tire_link_pattern = %r{<a\s+href="([^"]*\/shiny\/w-\d+\/h-\d+\/r-\d+\/?)"[^>]*>([^<]*)<\/a>}i

    text.gsub(tire_link_pattern) do |match|
      href = $1
      anchor_text = $2

      # Проверяем, содержит ли анкор типоразмер (например 215/55R17 или 215/55 R 17)
      if anchor_contains_tire_size?(anchor_text)
        # Анкор корректен - оставляем ссылку
        match
      else
        # Анкор не содержит размер - удаляем ссылку, оставляем текст
        Rails.logger.warn "Removed tire link with invalid anchor: #{anchor_text} (href: #{href})"
        anchor_text
      end
    end
  end

  # Проверяет, содержит ли текст анкора типоразмер шины
  # Допустимые форматы: 215/55R17, 215/55 R17, 215/55R 17, 215/55 R 17
  def anchor_contains_tire_size?(text)
    # Паттерн для типоразмера: ширина/профиль R радиус (с опциональными пробелами)
    text.match?(/\d{3}\s*\/\s*\d{2}\s*R\s*\d{2}/i)
  end

  # Исправляет ссылки на типоразмеры шин
  # Принцип: анкор = источник правды
  # Если анкор содержит типоразмер - генерируем правильную ссылку из него,
  # игнорируя что было в href (даже если там был битый URL)
  #
  # Примеры битых URL которые исправляются:
  # /shiny/275/65-r18/ -> /shiny/w-275/h-65/r-18/
  # /shiny/205-65-r16/ -> /shiny/w-205/h-65/r-16/
  # /ua/shiny/215/55/r16/ -> /ua/shiny/w-215/h-55/r-16/
  #
  # Примеры ссылок которые удаляются (URL с размером, но анкор без размера):
  # <a href="/shiny/275/65-r18/">зимові шини</a> -> зимові шини
  # <a href="/shiny/w-215/h-55/r-16/">купити</a> -> купити
  #
  # Примеры битых ссылок на бренд/сезон которые исправляются:
  # <a href="/shiny/kumnie/">Kumho</a> -> /shiny/kumho/
  # <a href="/shiny/zimnne/">зимові шини</a> -> /shiny/zimnie/
  def fix_tire_size_links(text)
    return text if text.blank?

    # Ищем ВСЕ ссылки в тексте
    link_pattern = /<a\s+href="([^"]*)"[^>]*>([^<]*)<\/a>/i

    text.gsub(link_pattern) do |match|
      href = $1
      anchor_text = $2

      # 1. Пробуем извлечь типоразмер из анкора
      correct_href = build_url_from_anchor(anchor_text, href)

      if correct_href
        if href == correct_href
          match
        else
          Rails.logger.info "Fixed tire link from anchor: #{href} -> #{correct_href} (anchor: '#{anchor_text}')"
          match.sub(href, correct_href)
        end
      elsif (correct_href = build_url_from_href(href))
        # 2. Пробуем извлечь размер из самого битого URL
        Rails.logger.info "Fixed tire link from href: #{href} -> #{correct_href}"
        match.sub(href, correct_href)
      elsif href_contains_tire_size_pattern?(href)
        # URL содержит размер, но анкор - нет -> удаляем ссылку
        Rails.logger.warn "Removed tire link with mismatched anchor: #{href} (anchor: '#{anchor_text}')"
        anchor_text
      elsif href_is_suspicious_shiny_url?(href)
        # 2. URL подозрительный (/shiny/kumnie/) - пробуем определить бренд или сезон из анкора
        brand_or_season_href = build_url_from_anchor_brand_or_season(anchor_text, href)

        if brand_or_season_href
          Rails.logger.info "Fixed brand/season link from anchor: #{href} -> #{brand_or_season_href} (anchor: '#{anchor_text}')"
          match.sub(href, brand_or_season_href)
        else
          # Не смогли определить - удаляем ссылку, оставляем текст
          Rails.logger.warn "Removed suspicious shiny link: #{href} (anchor: '#{anchor_text}')"
          anchor_text
        end
      else
        # Обычная ссылка - оставляем как есть
        match
      end
    end
  end

  # Проверяет, содержит ли URL паттерны размера шин
  def href_contains_tire_size_pattern?(href)
    return false if href.blank?

    tire_size_patterns = [
      /\/w-\d+\/h-\d+\/r-\d+/i,             # правильный: /w-265/h-60/r-18/
      /\/shiny\/\d{3}\/\d{2}-r\d{2}/i,      # битый: /shiny/275/65-r18/
      /\/shiny\/\d{3}-\d{2}-r\d{2}/i,       # битый: /shiny/205-65-r16/
      /\/shiny\/\d{3}\/\d{2}\/r-\d{2}/i,    # битый: /shiny/265/60/r-18/
      /\/shiny\/\d{3}\/\d{2}\/r\d{2}/i,     # битый: /shiny/215/55/r16/
      /\/shiny\/\d{3}\/\d{2}\/\d{2}/i,      # битый: /shiny/215/55/16/
      /[whr]\d*=\d+/i,                      # битый: w1=255, h=45, r=18, h1=35
      /[whr]\d+r\d+/i,                      # битый: w1r225, h1r45, r1r17, r1r6
      /\/shiny\/w\d+\/?$/i,                 # битый неполный: /shiny/w1/
    ]

    tire_size_patterns.any? { |pattern| href.match?(pattern) }
  end

  # Проверяет, является ли URL подозрительным (содержит /shiny/ но не валидный)
  # Например: /shiny/kumnie/ (склеенное kumho+zimnie)
  def href_is_suspicious_shiny_url?(href)
    return false if href.blank?
    return false unless href.include?('/shiny/')

    # Известные валидные паттерны URL
    valid_patterns = [
      /\/shiny\/w-\d+\/h-\d+\/r-\d+/i,           # размер
      /\/shiny\/r-\d+\//i,                        # только радиус
      /\/shiny\/(letnie|zimnie|vsesezonie)\//i,   # сезон
      /\/shiny\/[a-z]+-[a-z]+\//i,                # бренд с дефисом (bf-goodrich)
      /\/shiny\/auto\//i,                         # ссылка на авто
    ]

    # Если URL соответствует валидному паттерну - не подозрительный
    return false if valid_patterns.any? { |p| href.match?(p) }

    # Проверяем, есть ли бренд в URL
    brand_in_url = extract_brand_slug_from_url(href)
    return false if brand_in_url && Brand.exists?(url: "/shiny/#{brand_in_url}/")

    # URL содержит /shiny/something/ но не соответствует известным паттернам
    # Ловим как single-segment (/shiny/kumnie/), так и multi-segment (/shiny/w1=255/h1=35/r1=19/)
    href.match?(/\/shiny\/[^\/]+/)
  end

  # Извлекает slug бренда из URL
  def extract_brand_slug_from_url(href)
    match = href.match(/\/shiny\/([a-z0-9-]+)\/?$/i)
    match ? match[1].downcase : nil
  end

  # Пробует определить бренд или сезон из анкора и построить правильный URL
  def build_url_from_anchor_brand_or_season(anchor_text, original_href = '')
    lang_prefix = original_href.include?('/ua/') || @language == 'ua' ? '/ua' : ''

    # 1. Пробуем найти бренд в анкоре
    brand_url = find_brand_in_anchor(anchor_text)
    if brand_url
      return "#{lang_prefix}#{brand_url}"
    end

    # 2. Пробуем найти сезон в анкоре
    season_url = find_season_in_anchor(anchor_text)
    if season_url
      return "#{lang_prefix}#{season_url}"
    end

    nil
  end

  # Ищет название бренда в анкоре и возвращает URL
  def find_brand_in_anchor(anchor_text)
    return nil if anchor_text.blank?

    anchor_lower = anchor_text.downcase

    # Получаем все бренды шин из БД
    Brand.where(type_url: 0).find_each do |brand|
      brand_name_lower = brand.name.downcase
      # Проверяем, содержит ли анкор название бренда
      if anchor_lower.include?(brand_name_lower)
        return normalize_brand_url(brand.url) if brand.url.present?
      end
    end

    nil
  end

  # Ищет сезонность в анкоре и возвращает URL
  def find_season_in_anchor(anchor_text)
    return nil if anchor_text.blank?

    anchor_lower = anchor_text.downcase

    # Паттерны для определения сезонности
    season_patterns = {
      '/shiny/letnie/' => [
        /літн[іяюих]/i,           # українська
        /летн[иіяюых]/i,          # русский
      ],
      '/shiny/zimnie/' => [
        /зимов[іаую]/i,           # українська
        /зимн[іиіяюых]/i,         # русский
      ],
      '/shiny/vsesezonie/' => [
        /всесезонн[іиіяюых]/i,    # обе
        /всесезонк/i,
      ]
    }

    season_patterns.each do |url, patterns|
      if patterns.any? { |pattern| anchor_lower.match?(pattern) }
        return url
      end
    end

    nil
  end

  # Извлекает типоразмер из текста анкора и строит правильный URL
  # Поддерживаемые форматы анкора:
  # - "215/55R17", "215/55 R17", "215/55 R 17"
  # - "шини 215/55R17", "резина 215/55 R17"
  # - "215/55R17C" (коммерческие)
  def build_url_from_anchor(anchor_text, original_href = '')
    # Убираем пробелы для унификации поиска
    normalized = anchor_text.gsub(/\s+/, '').downcase

    # Паттерн: ширина/профиль R радиус (опционально C для коммерческих)
    if normalized =~ /(\d{3})\/(\d{2})r(\d{2})c?/i
      width, height, radius = $1, $2, $3

      return nil unless valid_tire_dimensions?(width, height, radius)

      # Определяем языковой префикс из оригинального href или из настроек
      lang_prefix = if original_href.include?('/ua/')
                      '/ua'
                    elsif @language == 'ua'
                      '/ua'
                    else
                      ''
                    end

      "#{lang_prefix}/shiny/w-#{width}/h-#{height}/r-#{radius}/"
    else
      nil
    end
  end

  # Извлекает типоразмер из битого URL и строит правильный
  # Парсит сегменты w/h/r, собирает цифры, ищет валидные размеры
  # Примеры:
  #   /shiny/w1=255/h1=35/r1=19/   → /shiny/w-255/h-35/r-19/
  #   /shiny/w1r225/h1r45/r1r17/   → /shiny/w-225/h-45/r-17/
  #   /shiny/w-225/h-50/r1r6/      → /shiny/w-225/h-50/r-16/
  #   /shiny/w1/                   → nil (неполный)
  def build_url_from_href(href)
    return nil if href.blank?
    return nil unless href.include?('/shiny/')

    # Извлекаем путь после /shiny/ (или /ua/shiny/)
    path = href.sub(%r{.*/shiny/}i, '')
    segments = path.split('/').reject(&:empty?)

    width = nil
    height = nil
    radius = nil

    segments.each do |seg|
      seg_lower = seg.downcase
      # Определяем тип параметра по первой букве
      case seg_lower[0]
      when 'w'
        width = extract_tire_value(seg_lower, :width)
      when 'h'
        height = extract_tire_value(seg_lower, :height)
      when 'r'
        radius = extract_tire_value(seg_lower, :radius)
      end
    end

    return nil unless width && height && radius
    return nil unless valid_tire_dimensions?(width, height, radius)

    lang_prefix = href.include?('/ua/') || @language == 'ua' ? '/ua' : ''
    "#{lang_prefix}/shiny/w-#{width}/h-#{height}/r-#{radius}/"
  end

  # Извлекает числовое значение из сегмента URL (w1=255 → 255, r1r6 → 16)
  # Собирает все цифры, затем ищет валидное число нужной разрядности с конца
  def extract_tire_value(segment, type)
    # Убираем первую букву (w/h/r) и собираем все цифры
    digits_only = segment[1..].gsub(/\D/, '')
    return nil if digits_only.empty?

    case type
    when :width
      # Ищем 3-значное число, предпочитаем с конца (реальное значение)
      # w1=255 → "1255" → берём "255"; w1r225 → "1225" → берём "225"
      (digits_only.length - 2).downto(0).each do |i|
        candidate = digits_only[i, 3].to_i
        return candidate if candidate >= 105 && candidate <= 495 && (candidate % 10 == 5)
      end
    when :height
      # Ищем 2-значное число, предпочитаем с конца
      # h1=35 → "135" → берём "35"; h1r45 → "145" → берём "45"
      (digits_only.length - 1).downto(0).each do |i|
        candidate = digits_only[i, 2].to_i
        return candidate if candidate >= 25 && candidate <= 85 && (candidate % 5 == 0)
      end
    when :radius
      # Ищем 2-значное число, предпочитаем с конца
      # r1=19 → "119" → берём "19"; r1r6 → "16" → берём "16"
      (digits_only.length - 1).downto(0).each do |i|
        candidate = digits_only[i, 2].to_i
        return candidate if candidate >= 12 && candidate <= 24
      end
    end

    nil
  end

  # Проверяет валидность размеров шин (только легковые)
  # w: 105-495, должна оканчиваться на 5 (105, 115, 125... 495)
  # h: 25-85, кратно 5 (25, 30, 35... 85)
  # r: 12-24
  def valid_tire_dimensions?(width, height, radius)
    w, h, r = width.to_i, height.to_i, radius.to_i
    w >= 105 && w <= 495 && (w % 10 == 5) &&
      h >= 25 && h <= 85 && (h % 5 == 0) &&
      r >= 12 && r <= 24
  end

  # Очищает ссылки: удаляет безанкорные и нормализует домены prokoleso.*
  # 1. Безанкорные ссылки (<a href="..."></a> или <a href="..."> </a>) - удаляются полностью
  # 2. Абсолютные ссылки prokoleso.* преобразуются в относительные:
  #    https://prokoleso.com/shiny/ -> /shiny/
  #    https://prokoleso.ua/ua/shiny/ -> /ua/shiny/
  def sanitize_links(text)
    return text if text.blank?

    # 1. Удаляем безанкорные ссылки (пустой или только пробелы анкор)
    text = text.gsub(/<a\s+[^>]*href="[^"]*"[^>]*>\s*<\/a>/i, '')

    # 2. Преобразуем абсолютные ссылки prokoleso.* в относительные
    # Поддерживаем: prokoleso.ua, prokoleso.com, prokoleso.ru и т.д.
    text = text.gsub(/href="https?:\/\/prokoleso\.[a-z]+(\.[a-z]+)?/i, 'href="')

    text
  end

  # Дедупликация ссылок: оставляет первое вхождение каждого href,
  # последующие разворачивает в plain text (оставляет только анкор).
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
        $& # возвращаем оригинальное совпадение
      end
    end
  end

  # Исправляет CTA-параграф: если в последнем <p> есть ссылка с анкором-предложением
  # (>60 символов), разворачивает её в plain text.
  def fix_cta_link_wrapping(text)
    return text if text.blank?

    # Находим последний <p>...</p>
    last_p_match = text.match(/.*(<p>.*?<\/p>)\s*\z/im)
    return text unless last_p_match

    last_p = last_p_match[1]
    fixed_p = last_p.gsub(/<a\s+[^>]*href="[^"]*"[^>]*>(.*?)<\/a>/im) do
      anchor = $1
      plain_anchor = anchor.gsub(/<[^>]+>/, '') # убираем вложенные теги для подсчёта длины
      if plain_anchor.length > 60
        Rails.logger.info "Fix CTA wrapping: unwrapped long anchor (#{plain_anchor.length} chars): \"#{plain_anchor.truncate(80)}\""
        anchor
      else
        $& # короткий анкор — оставляем ссылку
      end
    end

    text.sub(last_p, fixed_p)
  end

  # Удаляет все <img> теги из текста
  def remove_images(text)
    return text if text.blank?

    cleaned = text.gsub(/<img\s[^>]*>/i, '')
    # Удаляем пустые параграфы, оставшиеся после удаления изображений
    cleaned = cleaned.gsub(/<p>\s*<\/p>/i, '')
    cleaned
  end

  # Капитализирует первую букву текста в заголовках h1-h6
  def capitalize_headings(text)
    return text if text.blank?

    text.gsub(/<(h[1-6])([^>]*)>(.*?)<\/\1>/im) do
      tag = $1
      attrs = $2
      content = $3
      # Капитализируем первую букву текстового содержимого (пропускаем теги)
      capitalized = content.sub(/\A(\s*(?:<[^>]+>)*)(\p{L})/i) { "#{$1}#{$2.upcase}" }
      "<#{tag}#{attrs}>#{capitalized}</#{tag}>"
    end
  end

  def build_geographic_restrictions
    if @language == 'ua'
      <<~RESTRICTIONS
        ГЕОГРАФІЧНІ ОБМЕЖЕННЯ:
        - КАТЕГОРИЧНО ЗАБОРОНЕНО згадувати будь-які російські міста, регіони або топоніми
        - ЗАБОРОНЕНО: Москва, Санкт-Петербург, Росія, російський та будь-які інші російські географічні назви
        - ДОЗВОЛЕНО: тільки українські міста (Київ, Харків, Одеса, Львів, Дніпро тощо)
        - При згадці географії використовуй тільки Україну та українські топоніми
      RESTRICTIONS
    else
      <<~RESTRICTIONS
        ГЕОГРАФИЧЕСКИЕ ОГРАНИЧЕНИЯ:
        - КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО упоминать любые российские города, регионы или топонимы
        - ЗАПРЕЩЕНО: Москва, Санкт-Петербург, Россия, российский и любые другие российские географические названия
        - РАЗРЕШЕНО: только украинские города (Киев, Харьков, Одесса, Львов, Днепр и т.д.)
        - При упоминании географии используй только Украину и украинские топонимы
      RESTRICTIONS
    end
  end
end
