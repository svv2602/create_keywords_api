# app/services/seo_text_generator.rb

class SeoTextGenerator
    include StringProcessing
    include TextOptimization
  
  def initialize(params)
    @tire_description = params[:tire_description]
    @brand = params[:brand]
    @model = params[:model]
    @season = params[:season]
    @language = params[:language]
    @size = params[:size]
    @product_id = params[:product_id]
    @load_index = params[:load_index]
    @speed_index = params[:speed_index]
    @seo_requirements = params[:seo_requirements] || ''
    @links = parse_links(params[:links])
    @max_tokens = params[:max_tokens] || 2000
    @force_model = params[:force_model]  # Опциональный параметр для выбора модели
    @content_writer = ContentWriter.new(force_model: @force_model)
  end
  
  def generate
    prompt = build_generation_prompt
    Rails.logger.info "SEO Generator Prompt - Language: #{@language}"
    Rails.logger.info "SEO Generator Prompt - Language check: #{@language == 'ua' ? 'Ukrainian' : 'Russian'}"
    Rails.logger.info "SEO Generator Prompt preview: #{prompt.truncate(500)}"
    response = @content_writer.write_seo_text(prompt, @max_tokens)
      
      if response && response['choices'] && response['choices'][0]
        generated_text = response['choices'][0]['message']['content'].strip
        format_generated_text(generated_text)
      else
        nil
      end
    end
  
    private
  
  def build_generation_prompt
    language_instruction = @language == 'ua' ? 
      'КРИТИЧЕСКИ ВАЖНО: Генерируй текст ТОЛЬКО на украинском языке! Используй украинские слова: "зимові шини", "комерційний транспорт", "характеристики", "переваги" и т.д.' :
      'КРИТИЧЕСКИ ВАЖНО: Генерируй текст ТОЛЬКО на русском языке!'
    
    <<~PROMPT
      #{language_instruction}
      
      #{@language == 'ua' ? 'Створи SEO-оптимізований текст для сторінки шинного інтернет-магазину ProKoleso.' : 'Создай SEO-оптимизированный текст для страницы шинного интернет-магазина ProKoleso.'}

      #{@language == 'ua' ? 'ОПИС МОДЕЛІ ШИН:' : 'ОПИСАНИЕ МОДЕЛИ ШИН:'}
      #{@tire_description}

      #{@language == 'ua' ? 'ПАРАМЕТРИ:' : 'ПАРАМЕТРЫ:'}
      - #{@language == 'ua' ? 'Бренд' : 'Бренд'}: #{@brand}
      - #{@language == 'ua' ? 'Модель' : 'Модель'}: #{@model}
      - #{@language == 'ua' ? 'Сезон' : 'Сезон'}: #{@season}
      - #{@language == 'ua' ? 'Розмір' : 'Размер'}: #{@size}
      - #{@language == 'ua' ? 'Індекс навантаження' : 'Индекс нагрузки'}: #{@load_index}
      - #{@language == 'ua' ? 'Індекс швидкості' : 'Индекс скорости'}: #{@speed_index}
      - #{@language == 'ua' ? 'Мова' : 'Язык'}: #{@language}
      - Product ID: #{@product_id}

      #{build_seo_requirements_section}

      #{build_links_section}

      #{@language == 'ua' ? 'ВИМОГИ ДО ТЕКСТУ:' : 'ТРЕБОВАНИЯ К ТЕКСТУ:'}
      1. #{@language == 'ua' ? 'Створи структурований HTML-текст з заголовками H2, H3, H4' : 'Создай структурированный HTML-текст с заголовками H2, H3 , H4'}
      2. #{@language == 'ua' ? 'Включи природне входження ключових слів' : 'Включи естественное вхождение ключевых слов'}: "#{@brand} #{@model}", "#{@language == 'ua' ? 'зимові шини' : @season} #{@language == 'ua' ? 'шини' : 'шины'}", "#{@language == 'ua' ? 'шини' : 'шины'} #{@size}", "#{@load_index}#{@speed_index}"
      3. #{@language == 'ua' ? 'Додай інформативні абзаци про характеристики, переваги та застосування шин' : 'Добавь информативные абзацы о характеристиках, преимуществах и применении шин'}
      4. #{@language == 'ua' ? 'Використовуй списки та виділення для кращої читабельності' : 'Используй списки и выделения для лучшей читаемости'}
      5. #{@language == 'ua' ? 'Включи заклик до дії для покупки' : 'Включи призыв к действию для покупки'}
      6. #{@language == 'ua' ? 'Текст має бути унікальним та корисним для користувачів' : 'Текст должен быть уникальным и полезным для пользователей'}
      7. #{@language == 'ua' ? 'Довжина тексту' : 'Длина текста'}: #{@max_tokens / 4}-#{@max_tokens / 2} #{@language == 'ua' ? 'слів' : 'слов'}
      8. #{@language == 'ua' ? 'ОБОВ\'ЯЗКОВО органічно встав ВСІ надані посилання в текст (кожне посилання тільки ОДИН раз)' : 'ОБЯЗАТЕЛЬНО органично вставь ВСЕ предоставленные ссылки в текст (каждую ссылку только ОДИН раз)'}
      9. #{@language == 'ua' ? 'ВАЖЛИВО: Використовуй тільки об\'єктивний, технічний стиль викладу. НЕ використовуй особові займенники (я, мені, мій, мій досвід, я тестував, хочу відзначити тощо). Пиши від третьої особи в нейтральному тоні.' : 'ВАЖНО: Используй только объективный, технический стиль изложения. НЕ используй личные местоимения (я, мне, мой, мой опыт, я тестировал, хочу отметить и т.д.). Пиши от третьего лица в нейтральном тоне.'}
      10. #{@language == 'ua' ? 'Фокус на технічних характеристиках, перевагах та застосуванні шин без особистих оцінок та суб\'єктивних думок.' : 'Фокус на технических характеристиках, преимуществах и применении шин без личных оценок и субъективных мнений.'}

      #{@language == 'ua' ? 'СТРУКТУРА ТЕКСТУ:' : 'СТРУКТУРА ТЕКСТА:'}
      - H2: #{@language == 'ua' ? 'основний заголовок з брендом, моделлю та розміром' : 'основной заголовок с брендом, моделью и размером'}
      - H3: #{@language == 'ua' ? '3-4 підзаголовки за темами (характеристики, переваги, застосування, вибір)' : '3-4 подзаголовка по темам (характеристики, преимущества, применение, выбор)'}
      - #{@language == 'ua' ? 'Абзаци з детальною інформацією та органічно вставленими посиланнями' : 'Абзацы с подробной информацией и органично вставленными ссылками'}
      - #{@language == 'ua' ? 'Марковані списки для ключових особливостей' : 'Маркированные списки для ключевых особенностей'}
      - #{@language == 'ua' ? 'Заключний абзац з закликом до дії' : 'Заключительный абзац с призывом к действию'}

      #{@language == 'ua' ? 'СТИЛЬ ВИКЛАДУ:' : 'СТИЛЬ ИЗЛОЖЕНИЯ:'}
      #{@language == 'ua' ? 
        '- Використовуй безособові конструкції: "Шини характеризуються...", "Модель відрізняється...", "Особливістю є...", "Зимові шини забезпечують...", "Модель демонструє..."' :
        '- Используй безличные конструкции: "Шины характеризуются...", "Модель отличается...", "Особенностью является..."'
      }
      - #{@language == 'ua' ? 'Уникай' : 'Избегай'}: "Я эксплуатировал", "Мне понравилось", "Хочу отметить", "Лично тестировал"
      #{@language == 'ua' ? 
        '- Замість цього використовуй: "Шини забезпечують", "Модель демонструє", "Особливістю є", "Характеризується"' :
        '- Вместо этого используй: "Шины обеспечивают", "Модель демонстрирует", "Особенностью является", "Характеризуется"'
      }

      #{@language == 'ua' ? 'МОВА' : 'ЯЗЫК'}: #{@language == 'ua' ? 'Українська' : 'Русский'}

      #{@language == 'ua' ? 'ВАЖЛИВО ЗА МОВОЮ:' : 'ВАЖНО ПО ЯЗЫКУ:'} 
      #{@language == 'ua' ? 'Генеруй текст ТІЛЬКИ українською мовою. Використовуй українські слова та фрази.' : 'Генерируй текст ТОЛЬКО на русском языке.'}

      #{@language == 'ua' ? 'ВАЖЛИВО: Кожне посилання зі списку використовуй ТІЛЬКИ ОДИН РАЗ в тексті, вставляючи їх органічно в відповідний контекст. НЕ створюй вкладені посилання!' : 'ВАЖНО: Каждую ссылку из списка используй ТОЛЬКО ОДИН РАЗ в тексте, вставляя их органично в соответствующий контекст. НЕ создавай вложенные ссылки!'}

      #{@language == 'ua' ? 'Поверни тільки HTML-код без додаткових коментарів.' : 'Верни только HTML-код без дополнительных комментариев.'}
    PROMPT
  end
  
  def format_generated_text(text)
    # Очистка и форматирование сгенерированного текста
    text = clean_html_text(text)
    text = optimize_keywords(text)
    text
  end
  
    def clean_html_text(text)
      # Удаляем лишние пробелы и переносы строк
      text.gsub(/\s+/, ' ')
          .gsub(/>\s+</, '><')
          .strip
    end
  
  def parse_links(links_param)
    # Парсинг массива ссылок из параметров
    Rails.logger.debug "Links param: #{links_param.inspect}"
    Rails.logger.debug "Links param class: #{links_param.class}"
    
    return [] unless links_param.present?
    
    case links_param
    when Array
      # Обрабатываем массив
      result = links_param.map do |link|
        case link
        when Hash
          link
        when ActionController::Parameters
          link.to_unsafe_h  # Используем to_unsafe_h для получения всех данных
        else
          nil
        end
      end.compact
      
      Rails.logger.debug "Parsed links result: #{result.inspect}"
      result
    else
      Rails.logger.debug "Links param is not an array, returning empty"
      []
    end
  rescue => e
    Rails.logger.error "Error parsing links: #{e.message}"
    []
  end

  def build_seo_requirements_section
    return '' if @seo_requirements.blank?
    
    <<~SECTION
      #{@language == 'ua' ? 'SEO ВИМОГИ:' : 'SEO ТРЕБОВАНИЯ:'}
      #{@seo_requirements}
    SECTION
  end

  def build_links_section
    return '' if @links.empty?
    
    links_text = @links.map.with_index do |link, index|
      link_parts = []
      
      if link['brand'].present?
        link_parts << "<a href=\"#{format_link_with_language(link['brand'])}\">#{extract_brand_name(link['brand'])}</a>"
      end
      
      if link['model'].present?
        link_parts << "<a href=\"#{format_link_with_language(link['model'])}\">#{extract_model_name(link['model'])}</a>"
      end
      
      if link['brand_size'].present?
        link_parts << "<a href=\"#{format_link_with_language(link['brand_size'])}\">#{extract_size_info(link['brand_size'])}</a>"
      end
      
      if link['brand_sezon'].present?
        link_parts << "<a href=\"#{format_link_with_language(link['brand_sezon'])}\">#{extract_season_info(link['brand_sezon'])}</a>"
      end
      
      if link['size'].present?
        link_parts << "<a href=\"#{format_link_with_language(link['size'])}\">#{extract_size_info(link['size'])}</a>"
      end
      
      "#{index + 1}. #{link_parts.join(', ')}"
    end.join("\n")
    
    <<~SECTION
      #{@language == 'ua' ? 'ПОСИЛАННЯ ДЛЯ ОРГАНІЧНОЇ ВСТАВКИ В ТЕКСТ:' : 'ССЫЛКИ ДЛЯ ОРГАНИЧНОЙ ВСТАВКИ В ТЕКСТ:'}
      #{links_text}
      
      #{@language == 'ua' ? 'ІНСТРУКЦІЯ З ВИКОРИСТАННЯ ПОСИЛАНЬ:' : 'ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ ССЫЛОК:'}
      - #{@language == 'ua' ? 'Кожне посилання використовуй ТОЧНО ОДИН РАЗ в тексті' : 'Каждую ссылку используй ТОЧНО ОДИН РАЗ в тексте'}
      - #{@language == 'ua' ? 'Вставляй посилання органічно в відповідний контекст' : 'Вставляй ссылки органично в соответствующий контекст'}
      - #{@language == 'ua' ? 'Використовуй наданий HTML-код посилань БЕЗ ЗМІН' : 'Используй предоставленный HTML-код ссылок БЕЗ ИЗМЕНЕНИЙ'}
      - #{@language == 'ua' ? 'Посилання на бренд розміщуй в розділах про виробника' : 'Ссылки на бренд размещай в разделах о производителе'}
      - #{@language == 'ua' ? 'Посилання на модель - в описі конкретної моделі' : 'Ссылки на модель - в описании конкретной модели'}
      - #{@language == 'ua' ? 'Посилання на розміри - в технічних характеристиках' : 'Ссылки на размеры - в технических характеристиках'}
      - #{@language == 'ua' ? 'Посилання на сезон - в розділах про сезонність' : 'Ссылки на сезон - в разделах о сезонности'}
      - #{@language == 'ua' ? 'НЕ СТВОРЮЙ ВКЛАДЕНІ ПОСИЛАННЯ' : 'НЕ СОЗДАВАЙ ВЛОЖЕННЫЕ ССЫЛКИ'}
    SECTION
  end

  def extract_brand_name(url)
    # Извлекаем название бренда из URL
    brand = url.split('/').find { |part| part.present? && part != 'shiny' }
    brand&.capitalize || (@language == 'ua' ? 'бренд' : 'бренд')
  end

  def extract_model_name(url)
    # Извлекаем название модели из URL
    model = url.split('/').last&.gsub('-', ' ')
    model&.titleize || (@language == 'ua' ? 'модель' : 'модель')
  end

  def extract_size_info(url)
    # Извлекаем информацию о размере из URL
    size_parts = url.scan(/w-(\d+)|h-(\d+)|r-(\d+)/)
    if size_parts.any?
      width = size_parts.find { |w, h, r| w }&.first
      height = size_parts.find { |w, h, r| h }&.second
      radius = size_parts.find { |w, h, r| r }&.third
      
      size_str = [width, height].compact.join('/')
      size_str += " R#{radius}" if radius
      size_str.present? ? size_str : (@language == 'ua' ? 'розмір' : 'размер')
    else
      @language == 'ua' ? 'розмір' : 'размер'
    end
  end

  def extract_season_info(url)
    # Извлекаем информацию о сезоне из URL с учетом языка
    if url.include?('letnie')
      @language == 'ua' ? 'літні' : 'летние'
    elsif url.include?('zimnie')
      @language == 'ua' ? 'зимові' : 'зимние'
    elsif url.include?('vsesezone')
      @language == 'ua' ? 'всесезонні' : 'всесезонные'
    else
      @language == 'ua' ? 'шини' : 'шины'
    end
  end

  def format_link_with_language(url)
    # Форматируем ссылку с учетом языка
    return url if url.blank?
    
    # Если ссылка уже содержит префикс языка, возвращаем как есть
    return url if url.start_with?('/ua/') || url.start_with?('/ru/')
    
    # Добавляем префикс языка в зависимости от настройки
    if @language == 'ua'
      url.start_with?('/') ? "/ua#{url}" : "/ua/#{url}"
    else
      url
    end
  end

  def optimize_keywords(text)
    # Оптимизация ключевых слов в тексте с учетом языка
    text = text.gsub(/#{@brand}\s+#{@model}/i, "<strong>#{@brand} #{@model}</strong>")
    
    # Используем правильное слово "шины/шини" в зависимости от языка
    tires_word = @language == 'ua' ? 'шини' : 'шины'
    text = text.gsub(/#{@season}\s+#{tires_word}/i, "<strong>#{@season} #{tires_word}</strong>")
    text = text.gsub(/#{tires_word}\s+#{@size}/i, "<strong>#{tires_word} #{@size}</strong>")
    text = text.gsub(/#{@load_index}#{@speed_index}/i, "<strong>#{@load_index}#{@speed_index}</strong>")
    text
  end

  private
  end