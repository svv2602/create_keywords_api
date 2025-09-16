# app/services/seo_text_generator.rb

class SeoTextGenerator
    include StringProcessing
    include TextOptimization
  
    def initialize(params)
      @tire_description = params[:tire_description]
      @brand = params[:brand]
      @season = params[:season]
      @language = params[:language]
      @size = params[:size]
      @seo_requirements = params[:seo_requirements]
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
        - Сезон: #{@season}
        - Размер: #{@size}
        - Язык: #{@language}
  
        SEO ТРЕБОВАНИЯ:
        #{@seo_requirements}
  
        ТРЕБОВАНИЯ К ТЕКСТУ:
        1. Создай структурированный HTML-текст с заголовками H1, H2, H3
        2. Включи естественное вхождение ключевых слов: "#{@brand}", "#{@season} шины", "шины #{@size}"
        3. Добавь информативные абзацы о характеристиках, преимуществах и применении шин
        4. Используй списки и выделения для лучшей читаемости
        5. Включи призыв к действию для покупки
        6. Текст должен быть уникальным и полезным для пользователей
        7. Длина текста: #{@max_tokens / 4}-#{@max_tokens / 2} слов
  
        СТРУКТУРА ТЕКСТА:
        - H1: основной заголовок с брендом и размером
        - H2: 3-4 подзаголовка по темам (характеристики, преимущества, применение, выбор)
        - Абзацы с подробной информацией
        - Маркированные списки для ключевых особенностей
        - Заключительный абзац с призывом к действию
  
        ЯЗЫК: #{@language == 'ru' ? 'Русский' : 'Украинский'}
  
        Верни только HTML-код без дополнительных комментариев.
      PROMPT
    end
  
    def format_generated_text(text)
      # Очистка и форматирование сгенерированного текста
      text = clean_html_text(text)
      text = optimize_keywords(text)
      text = add_brand_links(text) if should_add_links?
      text
    end
  
    def clean_html_text(text)
      # Удаляем лишние пробелы и переносы строк
      text.gsub(/\s+/, ' ')
          .gsub(/>\s+</, '><')
          .strip
    end
  
    def optimize_keywords(text)
      # Оптимизация ключевых слов в тексте
      text = text.gsub(/#{@brand}/i, "<strong>#{@brand}</strong>")
      text = text.gsub(/#{@season}\s+шины/i, "<strong>#{@season} шины</strong>")
      text = text.gsub(/шины\s+#{@size}/i, "<strong>шины #{@size}</strong>")
      text
    end
  
    def add_brand_links(text)
      # Добавляем ссылки на бренд (если нужно)
      text.gsub(/#{@brand}/i, "<a href=\"/shiny/#{@brand.downcase}/\">#{@brand}</a>")
    end
  
    def should_add_links?
      # Логика определения необходимости добавления ссылок
      true
    end
  end