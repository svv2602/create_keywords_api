# app/services/car_seo_text_generator.rb
class CarSeoTextGenerator
  include StringProcessing

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

    prompt = build_prompt

    # Генерация текста через AI (увеличиваем max_tokens для более длинного текста)
    response = ContentWriter.new.write_seo_text(prompt, 4500)

    if response
      text = response['choices'][0]['message']['content'].strip
      text = clean_html_text(text)
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

  def clean_html_text(text)
    # Удаляем лишние пробелы и переносы строк, но сохраняем структуру HTML
    text.gsub(/\s+/, ' ')
        .gsub(/>\s+</, '><')
        .strip
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
        "#{index + 1}. <a href=\"#{url}\">шины #{size}</a>"
      else
        nil
      end
    end.compact.join("\n")
  end

  def build_brand_links
    # Генерируем ссылки на бренд и бренд+размеры
    brand_url = @language == 'ua' ? "/ua/shiny/auto/#{@brand.downcase}/#{@model.downcase}/" : "/shiny/auto/#{@brand.downcase}/#{@model.downcase}/"
    links = []
    links << "- <a href=\"#{brand_url}\">шины для #{@brand.capitalize} #{@model.capitalize}</a>"

    # Добавляем ссылки на размеры с брендом
    @typical_sizes.first(2).each do |size|
      if size =~ /(\d+)\/(\d+)R(\d+)/i
        width, height, radius = $1, $2, $3
        size_url = @language == 'ua' ? "/ua/shiny/w-#{width}/h-#{height}/r-#{radius}/" : "/shiny/w-#{width}/h-#{height}/r-#{radius}/"
        links << "- <a href=\"#{size_url}\">шины #{size} для #{@brand.capitalize} #{@model.capitalize}</a>"
      end
    end

    links.join("\n")
  end

  def build_russian_prompt
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

      ССЫЛКИ ДЛЯ ОРГАНИЧНОЙ ВСТАВКИ В ТЕКСТ:
      #{build_brand_links}

      #{build_size_links}

      ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ ССЫЛОК:
      - Каждую ссылку используй ТОЧНО ОДИН РАЗ в тексте
      - Вставляй ссылки органично в соответствующий контекст
      - Используй предоставленный HTML-код ссылок БЕЗ ИЗМЕНЕНИЙ
      - НЕ СОЗДАВАЙ ВЛОЖЕННЫЕ ССЫЛКИ

      ТРЕБОВАНИЯ К ТЕКСТУ:
      1. Создай структурированный HTML-текст с заголовками H2, H3, H4
      2. Включи естественное вхождение ключевых слов: "#{@brand.capitalize} #{@model.capitalize}", "шины для #{@brand.capitalize} #{@model.capitalize}"
      3. Добавь информативные абзацы о характеристиках, преимуществах и применении шин
      4. Используй списки (<ul>, <ol>) и выделения для лучшей читаемости
      5. Включи призыв к действию для покупки
      6. Текст должен быть уникальным и полезным для пользователей
      7. Длина текста: 2000-3500 знаков (для популярных моделей до 4000)
      8. ОБЯЗАТЕЛЬНО органично вставь ВСЕ предоставленные ссылки в текст (каждую ссылку только ОДИН раз)
      9. ВАЖНО: Используй только объективный, технический стиль изложения. НЕ используй личные местоимения (я, мне, мой, мой опыт, я тестировал, хочу отметить и т.д.). Пиши от третьего лица в нейтральном тоне.
      10. Фокус на технических характеристиках, преимуществах и применении шин без личных оценок и субъективных мнений.

      СТРУКТУРА ТЕКСТА:
      - H2: Шины для #{@brand.capitalize} #{@model.capitalize} - основной заголовок
      - H3: 3-4 подзаголовка по темам (типичные размеры, сезонность, выбор по параметрам, преимущества ProKoleso)
      - H4: дополнительные подзаголовки при необходимости
      - Абзацы с подробной информацией и органично вставленными ссылками
      - Маркированные или нумерованные списки для ключевых особенностей
      - Заключительный абзац с призывом к действию

      СТИЛЬ ИЗЛОЖЕНИЯ:
      - Используй безличные конструкции: "Шины характеризуются...", "Модель отличается...", "Особенностью является...", "Для #{@brand.capitalize} #{@model.capitalize} рекомендуются..."
      - Избегай: "Я эксплуатировал", "Мне понравилось", "Хочу отметить", "Лично тестировал"
      - Вместо этого используй: "Шины обеспечивают", "Модель демонстрирует", "Особенностью является", "Характеризуется"
      - Избегай местоимений "их", "них", "его", "ее"

      КЛЮЧЕВЫЕ ФРАЗЫ (использовать по одному разу каждую):
      - "Купить шины на #{@brand.capitalize} #{@model.capitalize}"
      - "Купить резину на #{@brand.capitalize} #{@model.capitalize}"

      ВАЖНО ПО ФОРМАТУ ССЫЛОК:
      - ВСЕГДА используй формат: /shiny/w-215/h-55/r-17/
      - НЕПРАВИЛЬНО: /shiny/215/55/r17/ или /shiny/w215/h55/r-17/
      - ПРАВИЛЬНО: /shiny/w-215/h-55/r-17/
      - Используй дефис после w-, h-, r- и слэш между параметрами

      ВАЖНО: Верни только HTML-код без дополнительных комментариев и пояснений.
    PROMPT

    prompt
  end

  def build_ukrainian_prompt
    # Перевод значений для украинского языка
    body_type_ua = translate_body_type(@body_type) if @body_type.present?

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

      ПОСИЛАННЯ ДЛЯ ОРГАНІЧНОЇ ВСТАВКИ В ТЕКСТ:
      #{build_brand_links}

      #{build_size_links}

      ІНСТРУКЦІЯ З ВИКОРИСТАННЯ ПОСИЛАНЬ:
      - Кожне посилання використовуй ТОЧНО ОДИН РАЗ в тексті
      - Вставляй посилання органічно у відповідний контекст
      - Використовуй наданий HTML-код посилань БЕЗ ЗМІН
      - НЕ СТВОРЮЙ ВКЛАДЕНІ ПОСИЛАННЯ

      ВИМОГИ ДО ТЕКСТУ:
      1. Створи структурований HTML-текст із заголовками H2, H3, H4
      2. Включи природне входження ключових слів: "#{@brand.capitalize} #{@model.capitalize}", "шини для #{@brand.capitalize} #{@model.capitalize}"
      3. Додай інформативні абзаци про характеристики, переваги та застосування шин
      4. Використовуй списки (<ul>, <ol>) та виділення для кращої читабельності
      5. Включи заклик до дії для покупки
      6. Текст має бути унікальним та корисним для користувачів
      7. Довжина тексту: 2000-3500 знаків (для популярних моделей до 4000)
      8. ОБОВ'ЯЗКОВО органічно встав ВСІ надані посилання в текст (кожне посилання тільки ОДИН раз)
      9. ВАЖЛИВО: Використовуй тільки об'єктивний, технічний стиль викладу. НЕ використовуй особові займенники (я, мені, мій, мій досвід, я тестував, хочу відзначити тощо). Пиши від третьої особи в нейтральному тоні.
      10. Фокус на технічних характеристиках, перевагах та застосуванні шин без особистих оцінок та суб'єктивних думок.

      СТРУКТУРА ТЕКСТУ:
      - H2: Шини для #{@brand.capitalize} #{@model.capitalize} - основний заголовок
      - H3: 3-4 підзаголовки за темами (типові розміри, сезонність, вибір за параметрами, переваги ProKoleso)
      - H4: додаткові підзаголовки при необхідності
      - Абзаци з детальною інформацією та органічно вставленими посиланнями
      - Марковані або нумеровані списки для ключових особливостей
      - Заключний абзац із закликом до дії

      СТИЛЬ ВИКЛАДУ:
      - Використовуй безособові конструкції: "Шини характеризуються...", "Модель відрізняється...", "Особливістю є...", "Для #{@brand.capitalize} #{@model.capitalize} рекомендуються..."
      - Уникай: "Я експлуатував", "Мені сподобалось", "Хочу відзначити", "Особисто тестував"
      - Замість цього використовуй: "Шини забезпечують", "Модель демонструє", "Особливістю є", "Характеризується"
      - Уникай займенників "їх", "них", "його", "її"

      КЛЮЧОВІ ФРАЗИ (використовувати по одному разу кожну):
      - "Купити шини на #{@brand.capitalize} #{@model.capitalize}"
      - "Купити резину на #{@brand.capitalize} #{@model.capitalize}"

      ВАЖЛИВО ПО ФОРМАТУ ПОСИЛАНЬ:
      - ЗАВЖДИ використовуй формат: /shiny/w-215/h-55/r-17/
      - НЕПРАВИЛЬНО: /shiny/215/55/r17/ або /shiny/w215/h55/r-17/
      - ПРАВИЛЬНО: /shiny/w-215/h-55/r-17/
      - Використовуй дефіс після w-, h-, r- та слеш між параметрами

      ВАЖЛИВО: Поверни тільки HTML-код без додаткових коментарів та пояснень.
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
end
