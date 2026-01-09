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
        ['оформіть замовлення онлайн', 'замовлення онлайн', 'замовити онлайн'] :
        ['оформите заказ онлайн', 'заказ онлайн', 'заказать онлайн']

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

    # Исправляем пробелы в URL типоразмеров (w -225 -> w-225)
    text = fix_spaces_in_tire_urls(text)

    # Удаляем циклические ссылки на текущую модель автомобиля
    text = remove_self_referencing_links(text)

    # Исправляем или удаляем некорректные ссылки на типоразмеры
    text = fix_tire_size_links(text)

    # Валидируем анкоры ссылок на типоразмеры (анкор должен содержать размер)
    text = validate_tire_link_anchors(text)

    # Сначала удаляем markdown блоки
    text = text.gsub(/```html\s*/, '').gsub(/```\s*$/, '')

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

    # Исправляем закрывающие теги с пробелами: </p > -> </p>, < /p> -> </p>
    text = text.gsub(/<\s*\/\s*(\w+)\s*>/i, '</\1>')

    # Исправляем сломанные теги от AI: <]/li] -> </li>, <]/p] -> </p> и т.д.
    # AI иногда генерирует квадратные скобки вместо угловых
    text = text.gsub(/<\]\/(\w+)\]/, '</\1>')   # <]/li] -> </li>
    text = text.gsub(/\[\/(\w+)\]/, '</\1>')    # [/li] -> </li>
    text = text.gsub(/<\/(\w+)\]/, '</\1>')     # </li] -> </li>
    text = text.gsub(/<\](\w+)\]/, '<\1>')      # <]li] -> <li>
    text = text.gsub(/\[(\w+)\](?=[^a-z])/i, '<\1>') # [li] -> <li> (но не [слово])

    # Если текст не заканчивается на </p>, добавляем его
    text += '</p>' unless text.strip.end_with?('</p>')

    # Удаляем атрибуты
    text = text.gsub(/\s*class="[^"]*"/,  '')                 # Удаляем классы
    text = text.gsub(/\s*style="[^"]*"/, '')                  # Удаляем inline стили

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
    @typical_sizes.map.with_index do |size, index|
      # Парсим размер типа "215/55R17"
      if size =~ /(\d+)\/(\d+)R(\d+)/i
        width, height, radius = $1, $2, $3
        url = @language == 'ua' ? "/ua/shiny/w-#{width}/h-#{height}/r-#{radius}/" : "/shiny/w-#{width}/h-#{height}/r-#{radius}/"
        tires_word = @language == 'ua' ? 'шини' : 'шины'
        "#{index + 1}. <a href=\"#{url}\">#{tires_word} #{size}</a>"
      else
        nil
      end
    end.compact.join("\n")
  end

  def build_brand_links
    # Генерируем ссылки на бренд и бренд+размеры
    brand_url = @language == 'ua' ? "/ua/shiny/auto/#{@brand.downcase}/#{@model.downcase}/" : "/shiny/auto/#{@brand.downcase}/#{@model.downcase}/"
    tires_word = @language == 'ua' ? 'шини для' : 'шины для'
    links = []
    links << "- <a href=\"#{brand_url}\">#{tires_word} #{@brand.capitalize} #{@model.capitalize}</a>"

    # Добавляем ссылки на размеры с брендом
    @typical_sizes.first(2).each do |size|
      if size =~ /(\d+)\/(\d+)R(\d+)/i
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
        url = brand_record.url
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

  # Исправляет пробелы в URL типоразмеров шин
  # Неправильно: /shiny/w -225/h -35/r -18/ (пробел между буквой и дефисом)
  # Правильно: /shiny/w-225/h-35/r-18/
  def fix_spaces_in_tire_urls(text)
    return text if text.blank?

    # Паттерн для поиска ссылок с пробелами в URL
    # w -225 -> w-225, h -35 -> h-35, r -18 -> r-18
    original_text = text.dup

    # Исправляем пробелы в href атрибутах
    text = text.gsub(/href="([^"]*)"/) do |match|
      href = $1
      # Исправляем w -XXX -> w-XXX, h -XX -> h-XX, r -XX -> r-XX
      fixed_href = href.gsub(/([whr])\s+-(\d+)/, '\1-\2')
      if fixed_href != href
        Rails.logger.info "Fixed spaces in tire URL: #{href} -> #{fixed_href}"
      end
      "href=\"#{fixed_href}\""
    end

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
  # Если анкор содержит типоразмер - генерируем правильную ссылку из него
  def fix_tire_size_links(text)
    return text if text.blank?

    # Паттерн для поиска всех ссылок на /shiny/
    link_pattern = /<a\s+href="([^"]*\/shiny\/[^"]*)"[^>]*>([^<]*)<\/a>/i

    text.gsub(link_pattern) do |match|
      href = $1
      anchor_text = $2

      # Пробуем извлечь типоразмер из анкора
      correct_href = build_url_from_anchor(anchor_text)

      if correct_href
        # Анкор содержит типоразмер - проверяем, нужно ли исправлять ссылку
        if href == correct_href
          # Ссылка уже правильная
          match
        else
          # Ссылка неправильная - заменяем на правильную
          Rails.logger.info "Fixed tire link: #{href} -> #{correct_href} (from anchor: #{anchor_text})"
          match.sub(href, correct_href)
        end
      else
        # Анкор не содержит типоразмер - это ссылка на бренд или что-то другое
        match
      end
    end
  end

  # Извлекает типоразмер из текста и строит правильный URL
  # Нормализует текст: убирает пробелы, приводит к нижнему регистру
  # Примеры анкоров: "245/45R18", "245/45 R18", "275/45 R 19", "шини 215/55R17"
  def build_url_from_anchor(anchor_text)
    # Нормализуем текст для поиска размера
    normalized = anchor_text.gsub(/\s+/, '').downcase

    # Паттерн для извлечения размера: 245/45r18
    if normalized =~ /(\d{3})\/(\d{2})r(\d{2})/i
      width = $1
      height = $2
      radius = $3

      # Проверяем валидность размеров
      return nil unless valid_tire_dimensions?(width, height, radius)

      # Добавляем языковой префикс если нужно
      lang_prefix = @language == 'ua' ? '/ua' : ''
      "#{lang_prefix}/shiny/w-#{width}/h-#{height}/r-#{radius}/"
    else
      nil
    end
  end

  # Проверяет валидность размеров шин
  def valid_tire_dimensions?(width, height, radius)
    w = width.to_i
    h = height.to_i
    r = radius.to_i

    # Ширина обычно от 125 до 355
    # Профиль от 25 до 85 (или 0 для специальных)
    # Радиус от 12 до 24
    w >= 125 && w <= 355 &&
      h >= 0 && h <= 85 &&
      r >= 12 && r <= 24
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
