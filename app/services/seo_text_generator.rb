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
    @content_writer = ContentWriter.new
  end
  
    def generate
      prompt = build_generation_prompt
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
    <<~PROMPT
      Создай SEO-оптимизированный текст для страницы шинного интернет-магазина ProKoleso.

      ОПИСАНИЕ МОДЕЛИ ШИН:
      #{@tire_description}

      ПАРАМЕТРЫ:
      - Бренд: #{@brand}
      - Модель: #{@model}
      - Сезон: #{@season}
      - Размер: #{@size}
      - Индекс нагрузки: #{@load_index}
      - Индекс скорости: #{@speed_index}
      - Язык: #{@language}
      - Product ID: #{@product_id}

      #{build_seo_requirements_section}

      #{build_links_section}

      ТРЕБОВАНИЯ К ТЕКСТУ:
      1. Создай структурированный HTML-текст с заголовками H2, H3 , H4
      2. Включи естественное вхождение ключевых слов: "#{@brand} #{@model}", "#{@season} шины", "шины #{@size}", "#{@load_index}#{@speed_index}"
      3. Добавь информативные абзацы о характеристиках, преимуществах и применении шин
      4. Используй списки и выделения для лучшей читаемости
      5. Включи призыв к действию для покупки
      6. Текст должен быть уникальным и полезным для пользователей
      7. Длина текста: #{@max_tokens / 4}-#{@max_tokens / 2} слов
      8. ОБЯЗАТЕЛЬНО органично вставь ВСЕ предоставленные ссылки в текст (каждую ссылку только ОДИН раз)

      СТРУКТУРА ТЕКСТА:
      - H2: основной заголовок с брендом, моделью и размером
      - H3: 3-4 подзаголовка по темам (характеристики, преимущества, применение, выбор)
      - Абзацы с подробной информацией и органично вставленными ссылками
      - Маркированные списки для ключевых особенностей
      - Заключительный абзац с призывом к действию

      ЯЗЫК: #{@language == 'ru' ? 'Русский' : 'Украинский'}

      ВАЖНО: Каждую ссылку из списка используй ТОЛЬКО ОДИН РАЗ в тексте, вставляя их органично в соответствующий контекст. НЕ создавай вложенные ссылки!

      Верни только HTML-код без дополнительных комментариев.
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
      SEO ТРЕБОВАНИЯ:
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
      ССЫЛКИ ДЛЯ ОРГАНИЧНОЙ ВСТАВКИ В ТЕКСТ:
      #{links_text}
      
      ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ ССЫЛОК:
      - Каждую ссылку используй ТОЧНО ОДИН РАЗ в тексте
      - Вставляй ссылки органично в соответствующий контекст
      - Используй предоставленный HTML-код ссылок БЕЗ ИЗМЕНЕНИЙ
      - Ссылки на бренд размещай в разделах о производителе
      - Ссылки на модель - в описании конкретной модели
      - Ссылки на размеры - в технических характеристиках
      - Ссылки на сезон - в разделах о сезонности
      - НЕ СОЗДАВАЙ ВЛОЖЕННЫЕ ССЫЛКИ
    SECTION
  end

  def extract_brand_name(url)
    # Извлекаем название бренда из URL
    brand = url.split('/').find { |part| part.present? && part != 'shiny' }
    brand&.capitalize || 'бренд'
  end

  def extract_model_name(url)
    # Извлекаем название модели из URL
    model = url.split('/').last&.gsub('-', ' ')
    model&.titleize || 'модель'
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
      size_str.present? ? size_str : 'размер'
    else
      'размер'
    end
  end

  def extract_season_info(url)
    # Извлекаем информацию о сезоне из URL
    if url.include?('letnie')
      'летние'
    elsif url.include?('zimnie')
      'зимние'
    elsif url.include?('vsesezone')
      'всесезонные'
    else
      'шины'
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
    # Оптимизация ключевых слов в тексте
    text = text.gsub(/#{@brand}\s+#{@model}/i, "<strong>#{@brand} #{@model}</strong>")
    text = text.gsub(/#{@season}\s+шины/i, "<strong>#{@season} шины</strong>")
    text = text.gsub(/шины\s+#{@size}/i, "<strong>шины #{@size}</strong>")
    text = text.gsub(/#{@load_index}#{@speed_index}/i, "<strong>#{@load_index}#{@speed_index}</strong>")
    text
  end

  private
  end