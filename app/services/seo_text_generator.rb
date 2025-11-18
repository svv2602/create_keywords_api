# app/services/seo_text_generator.rb

class SeoTextGenerator
    include StringProcessing
    include TextOptimization
    include TextCompletenessValidation
  
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

        # Проверка целостности сгенерированного текста
        unless text_complete?(generated_text)
          log_incomplete_text_warning("#{@brand} #{@model} #{@size} (#{@language})")
          Rails.logger.warn "Text appears incomplete, attempting to complete it..."

          # Пытаемся автоматически завершить обрезанный текст
          completed_text = complete_truncated_text(generated_text)

          if completed_text && text_complete?(completed_text)
            Rails.logger.info "Text successfully completed!"
            generated_text = completed_text
          else
            Rails.logger.error "Failed to complete text - returning nil"
            return nil
          end
        end

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
      2. #{@language == 'ua' ? 'В ЗАГОЛОВКАХ НЕ використовуй ВЕЛИКІ ЛІТЕРИ (CAPS LOCK) - пиши звичайним регістром: "спортивні шини для динамічної їзди", а НЕ "СПОРТИВНІ ШИНИ ДЛЯ ДИНАМІЧНОЇ ЇЗДИ"' : 'В ЗАГОЛОВКАХ НЕ используй ЗАГЛАВНЫЕ БУКВЫ (CAPS LOCK) - пиши обычным регистром: "спортивные шины для динамичной езды", а НЕ "СПОРТИВНЫЕ ШИНЫ ДЛЯ ДИНАМИЧНОЙ ЕЗДЫ"'}
      3. #{@language == 'ua' ? 'Включи природне входження ключових слів' : 'Включи естественное вхождение ключевых слов'}: "#{@brand} #{@model}", "#{@language == 'ua' ? 'зимові шини' : @season} #{@language == 'ua' ? 'шини' : 'шины'}", "#{@language == 'ua' ? 'шини' : 'шины'} #{@size}", "#{@load_index}#{@speed_index}"
      4. #{@language == 'ua' ? 'Додай інформативні абзаци про характеристики, переваги та застосування шин' : 'Добавь информативные абзацы о характеристиках, преимуществах и применении шин'}
      5. #{@language == 'ua' ? 'Використовуй списки та виділення для кращої читабельності' : 'Используй списки и выделения для лучшей читаемости'}
      6. #{@language == 'ua' ? 'Включи заклик до дії для покупки' : 'Включи призыв к действию для покупки'}
      7. #{@language == 'ua' ? 'Текст має бути унікальним та корисним для користувачів' : 'Текст должен быть уникальным и полезным для пользователей'}
      8. #{@language == 'ua' ? 'Довжина тексту' : 'Длина текста'}: #{@max_tokens / 4}-#{@max_tokens / 2} #{@language == 'ua' ? 'слів' : 'слов'}
      9. #{@language == 'ua' ? 'ОБОВ\'ЯЗКОВО органічно встав ВСІ надані посилання в текст (кожне посилання тільки ОДИН раз)' : 'ОБЯЗАТЕЛЬНО органично вставь ВСЕ предоставленные ссылки в текст (каждую ссылку только ОДИН раз)'}
      10. #{@language == 'ua' ? 'ВАЖЛИВО: Використовуй тільки об\'єктивний, технічний стиль викладу. НЕ використовуй особові займенники (я, мені, мій, мій досвід, я тестував, хочу відзначити тощо). Пиши від третьої особи в нейтральному тоні.' : 'ВАЖНО: Используй только объективный, технический стиль изложения. НЕ используй личные местоимения (я, мне, мой, мой опыт, я тестировал, хочу отметить и т.д.). Пиши от третьего лица в нейтральном тоне.'}
      11. #{@language == 'ua' ? 'Фокус на технічних характеристиках, перевагах та застосуванні шин без особистих оцінок та суб\'єктивних думок.' : 'Фокус на технических характеристиках, преимуществах и применении шин без личных оценок и субъективных мнений.'}

      #{@language == 'ua' ? 'ПРАВИЛА ФОРМАТУВАННЯ:' : 'ПРАВИЛА ФОРМАТИРОВАНИЯ:'}
      - #{@language == 'ua' ? 'НЕ виділяй жирним (<strong>) текст в заголовках H2, H3, H4' : 'НЕ выделяй жирным (<strong>) текст в заголовках H2, H3, H4'}
      - #{@language == 'ua' ? 'НЕ використовуй вкладені теги <strong><strong></strong></strong>' : 'НЕ используй вложенные теги <strong><strong></strong></strong>'}
      - #{@language == 'ua' ? 'НЕ виділяй жирним текст всередині посилань <a>' : 'НЕ выделяй жирным текст внутри ссылок <a>'}
      - #{@language == 'ua' ? 'НЕ дублюй інформацію - кожен факт згадуй тільки один раз' : 'НЕ дублируй информацию - каждый факт упоминай только один раз'}

      #{@language == 'ua' ? 'СТРУКТУРА ТЕКСТУ:' : 'СТРУКТУРА ТЕКСТА:'}
      - H2: #{@language == 'ua' ? 'основний заголовок з брендом, моделлю та розміром' : 'основной заголовок с брендом, моделью и размером'}
      - H3: #{@language == 'ua' ? '3-4 підзаголовки за темами (характеристики, переваги, застосування, вибір)' : '3-4 подзаголовка по темам (характеристики, преимущества, применение, выбор)'}
      - #{@language == 'ua' ? 'Абзаци з детальною інформацією та органічно вставленими посиланнями' : 'Абзацы с подробной информацией и органично вставленными ссылками'}
      - #{@language == 'ua' ? 'Марковані списки для ключових особливостей' : 'Маркированные списки для ключевых особенностей'}
      - #{@language == 'ua' ? 'ЗАВЕРШЕННЯ ТЕКСТУ: Одне коротке речення без заголовка з фразою "оформіть замовлення онлайн".' : 'ЗАВЕРШЕНИЕ ТЕКСТА: Одно краткое предложение без заголовка с фразой "оформите заказ онлайн".'}
        #{@language == 'ua' ?
          'Варіанти формулювання (обери ТОЧНО один з наведених):
          - "Підібрати шини #{@brand} #{@model} #{@size} в каталозі та оформити замовлення онлайн можна на ProKoleso.ua"
          - "Вибрати та купити шини #{@brand} #{@model} #{@size} можна в інтернет-магазині ProKoleso - оформіть замовлення онлайн."
          - "Підберіть шини #{@brand} #{@model} #{@size} в каталозі ProKoleso та оформіть замовлення онлайн."
          ВАЖЛИВО: Використовуй ЛИШЕ наведені варіанти БЕЗ змін і доповнень. НЕ додавай "через кошик", "достатньо", "передбачена консультація" та інші пояснення!' :
          'Варианты формулировки (выбери ТОЧНО один из указанных):
          - "Подобрать шины #{@brand} #{@model} #{@size} в каталоге и оформить заказ онлайн можно на ProKoleso.ua"
          - "Выбрать и купить шины #{@brand} #{@model} #{@size} можно в интернет-магазине ProKoleso - оформите заказ онлайн."
          - "Подберите шины #{@brand} #{@model} #{@size} в каталоге ProKoleso и оформите заказ онлайн."
          ВАЖНО: Используй ТОЛЬКО указанные варианты БЕЗ изменений и дополнений. НЕ добавляй "через корзину", "достаточно", "предусмотрена консультация" и другие пояснения!'
        }

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
    # optimize_keywords удален - AI сам добавит выделения согласно промпту
    text
  end
  
    def clean_html_text(text)
      # Удаляем лишние пробелы и переносы строк
      text = text.gsub(/\s+/, ' ')
          .gsub(/>\s+</, '><')
          .strip

      # Если текст не заканчивается на </p>, добавляем его
      text += '</p>' unless text.strip.end_with?('</p>')

      text
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


  # Автоматически завершает обрезанный текст
  def complete_truncated_text(truncated_text)
    Rails.logger.info "Attempting to complete truncated text..."

    # Определяем, что именно отсутствует в тексте
    missing_elements = analyze_missing_elements(truncated_text)

    completion_prompt = build_completion_prompt(truncated_text, missing_elements)

    # Используем меньше токенов для дописывания (500-800 достаточно для завершения)
    response = @content_writer.write_seo_text(completion_prompt, 800)

    if response && response['choices'] && response['choices'][0]
      completion = response['choices'][0]['message']['content'].strip

      # Объединяем исходный текст с дописанным
      merge_texts(truncated_text, completion)
    else
      nil
    end
  rescue => e
    Rails.logger.error "Error completing text: #{e.message}"
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
      "Тобі надано незавершений SEO-текст про шини #{@brand} #{@model} #{@size}."
    else
      "Тебе предоставлен незавершенный SEO-текст о шинах #{@brand} #{@model} #{@size}."
    end

    requirements = []
    if missing_elements.include?(:cta) || missing_elements.include?(:buy_phrase) || missing_elements.include?(:final_paragraph)
      requirements << if @language == 'ua'
        "Додай заключний параграф <p> з фразами 'Купити шини на #{@brand} #{@model}' та 'оформіть замовлення онлайн'"
      else
        "Добавь заключительный параграф <p> с фразами 'Купить шины #{@brand} #{@model}' и 'оформите заказ онлайн'"
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
    # Если да - находим незавершенное предложение и удаляем его
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
        Rails.logger.info "Removed incomplete CTA paragraph from original text"
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

  private
  end