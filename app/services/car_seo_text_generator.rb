# app/services/car_seo_text_generator.rb
class CarSeoTextGenerator
  include StringProcessing
  include TextCompletenessValidation

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

    # Генерация текста через AI
    # 3000 токенов = примерно 2000-2500 слов = 8000-12000 символов
    # Уменьшенное значение для уменьшения вероятности обрезания текста
    response = ContentWriter.new.write_seo_text(prompt, 3000)

    if response
      text = response['choices'][0]['message']['content'].strip

      Rails.logger.info "Raw AI response length: #{text.length} characters"
      Rails.logger.info "Raw text encoding: #{text.encoding}"
      Rails.logger.info "Raw text sample (first 200 chars): #{text[0..200]}"

      text = clean_html_text(text)

      Rails.logger.info "After clean_html_text length: #{text.length}"
      Rails.logger.info "Before normalization sample (last 200 chars): #{text[-200..-1]}" if @language == 'ua'

      # Нормализуем украинский текст (заменяем латиницу на кириллицу)
      if @language == 'ua'
        text = normalize_ukrainian_text(text)
        Rails.logger.info "After normalization sample (last 200 chars): #{text[-200..-1]}"
      end

      # Проверка на обрезанный текст
      cta_phrases = @language == 'ru' ?
        ['оформите заказ онлайн', 'оформіть замовлення онлайн'] :
        ['оформіть замовлення онлайн', 'оформите заказ онлайн']

      # Проверка целостности текста
      unless text_complete?(text, required_phrases: cta_phrases)
        log_incomplete_text_warning("#{@brand} #{@model} (#{@language})")
        Rails.logger.error "Text completeness check failed!"
        Rails.logger.error "Text preview (last 200 chars): #{text[-200..-1]}"
        return { error: 'Generated text is incomplete. Please try again or reduce text length requirements.' }
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

  def normalize_ukrainian_text(text)
    # Карта замены латинских букв на украинские кириллические
    # AI иногда генерирует украинский текст с латинскими символами, похожими на кириллицу
    latin_to_cyrillic = {
      'a' => 'а', 'A' => 'А',
      'e' => 'е', 'E' => 'Е',
      'i' => 'і', 'I' => 'І',
      'o' => 'о', 'O' => 'О',
      'p' => 'р', 'P' => 'Р',
      'c' => 'с', 'C' => 'С',
      'y' => 'у', 'Y' => 'У',
      'x' => 'х', 'X' => 'Х',
      'k' => 'к', 'K' => 'К',
      'M' => 'М', 'm' => 'м',
      'T' => 'Т', 't' => 'т',
      'H' => 'Н', 'h' => 'н',
      'B' => 'В', 'b' => 'в',
      'r' => 'г', 'R' => 'Г'  # r часто используется вместо г
    }

    # Загружаем список брендов шин из базы данных (только латинские названия)
    # Кешируем в переменной экземпляра для производительности
    @tire_brands ||= Brand.pluck(:name).compact.uniq.select { |b| b.match?(/^[A-Za-z\s']+$/) }

    # Добавляем бренд и модель автомобиля в список защищаемых слов
    protected_words = @tire_brands.dup
    protected_words << @brand if @brand.present? && @brand.match?(/^[A-Za-z\s']+$/)
    protected_words << @model if @model.present? && @model.match?(/^[A-Za-z\s']+$/)
    protected_words << @brand.capitalize if @brand.present?
    protected_words << @model.capitalize if @model.present?
    protected_words.uniq!

    # Разбиваем на теги и текст
    parts = text.split(/(<[^>]+>)/)

    parts.map do |part|
      # Если это не HTML-тег, нормализуем
      if !part.start_with?('<')
        # Сначала защищаем названия (заменяем на плейсхолдеры)
        word_placeholders = {}
        normalized = part.dup

        protected_words.each_with_index do |word, index|
          if normalized.include?(word)
            # Используем плейсхолдер с цифрами и подчеркиваниями, без латинских букв
            placeholder = "___#{index}___"
            normalized.gsub!(word, placeholder)
            word_placeholders[placeholder] = word
          end
        end

        # Проходим несколько раз для замены всех вхождений латиницы на кириллицу
        3.times do
          latin_to_cyrillic.each do |latin, cyrillic|
            # Агрессивная замена: заменяем все латинские буквы на кириллические
            # если хотя бы одна кириллическая буква есть в соседних 5 символах
            normalized.gsub!(/(.{0,5})#{Regexp.escape(latin)}(.{0,5})/) do
              before, after = $1, $2
              # Если рядом есть кириллица - заменяем
              if before =~ /[а-яіїєґА-ЯІЇЄҐ]/ || after =~ /[а-яіїєґА-ЯІЇЄҐ]/
                "#{before}#{cyrillic}#{after}"
              else
                "#{before}#{latin}#{after}"
              end
            end
          end
        end

        # Восстанавливаем защищенные слова
        word_placeholders.each do |placeholder, word|
          normalized.gsub!(placeholder, word)
        end

        normalized
      else
        part
      end
    end.join
  end

  def clean_html_text(text)
    # Удаляем лишние пробелы и переносы строк, но сохраняем структуру HTML
    # Также удаляем возможные div, классы и стили

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
      1. НЕ используй <div>, классы, ID или <style> - только чистый HTML с заголовками, параграфами и списками
      2. Начни СРАЗУ с заголовка <h2>Шины для #{@brand.capitalize} #{@model.capitalize}</h2>
      3. Используй списки (<ul> или <ol>) для перечислений
      4. Длина текста: 1500-2500 знаков (компактный формат)
      5. ОБЯЗАТЕЛЬНО органично вставь ВСЕ предоставленные ссылки в текст (каждую ссылку только ОДИН раз)
      6. Используй только объективный, технический стиль изложения. НЕ используй личные местоимения (я, мне, мой и т.д.)

      СТРУКТУРА ТЕКСТА (строго следуй этому порядку):

      1. <h2>Шины для #{@brand.capitalize} #{@model.capitalize}</h2>

      2. Краткое вступление (2-3 предложения в теге <p>):
         - Упомяни "шины для #{@brand.capitalize} #{@model.capitalize}"
         #{@body_type.present? ? "- Укажи тип кузова: #{@body_type}" : "- Укажи тип кузова или класс автомобиля (если можешь определить)"}
         - Выдели, что это подбор по параметрам (размеру, сезону, стилю вождения)

      3. <h3>Типичные размеры шин для #{@brand.capitalize} #{@model.capitalize}</h3>
         <p>Краткое описание размерного ряда (1-2 предложения)</p>
         <ul> со списком всех предоставленных размеров с их особенностями (используй все ссылки на размеры)

      4. <h3>Популярные бренды и их особенности</h3>
         <p>Информация о рекомендуемых производителях шин для этой модели (Bridgestone, Michelin, Continental, Nokian и др.) - кратко, 2-3 предложения с упоминанием сезонности и типов шин</p>

      5. <h3>Рекомендации по подбору шин</h3>
         <ul> или <ol> с 4-5 пунктами:
           <li>Индексы нагрузки и скорости для данной модели</li>
           <li>Выбор сезонности (лето, зима, всесезонка)</li>
           <li>Рисунок протектора под стиль вождения</li>
           <li>Рекомендуемое давление</li>
         </ul>

      6. <h3>Преимущества ProKoleso</h3>
         <p>Краткое описание преимуществ (2-3 предложения): широкий выбор, проверенные бренды, доставка, консультация</p>

      7. ФИНАЛЬНЫЙ ПАРАГРАФ С CTA (ОБЯЗАТЕЛЬНО!):
         <p>ОБЯЗАТЕЛЬНО должен содержать:
         - Фразу "Купить шины на #{@brand.capitalize} #{@model.capitalize}" или "Купить резину на #{@brand.capitalize} #{@model.capitalize}"
         - Завершающую фразу "оформите заказ онлайн" (именно эти слова!)

         Пример: "Купить шины на #{@brand.capitalize} #{@model.capitalize} легко в каталоге ProKoleso. Выберите подходящий размер и бренд, получите консультацию специалиста и оформите заказ онлайн."
         </p>

      СТИЛЬ ИЗЛОЖЕНИЯ:
      - Используй безличные конструкции: "Шины характеризуются...", "Модель отличается...", "Для #{@brand.capitalize} #{@model.capitalize} рекомендуются..."
      - Избегай местоимений "их", "них", "его", "ее"

      ВАЖНО ПО ФОРМАТУ ССЫЛОК:
      - ВСЕГДА используй формат: /shiny/w-215/h-55/r-17/
      - НЕПРАВИЛЬНО: /shiny/215/55/r17/ или /shiny/w215/h55/r-17/
      - ПРАВИЛЬНО: /shiny/w-215/h-55/r-17/

      ВАЖНО: Верни ТОЛЬКО чистый HTML-код БЕЗ <div>, БЕЗ классов, БЕЗ <style>, БЕЗ markdown блоков. Начни сразу с <h2>.
      НЕ ДОБАВЛЯЙ теги <!DOCTYPE>, <html>, <head>, <body> - ТОЛЬКО содержимое начиная с <h2> и заканчивая </p>.
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
      1. НЕ використовуй <div>, класи, ID або <style> - тільки чистий HTML із заголовками, параграфами та списками
      2. Почни ОДРАЗУ з заголовка <h2>Шини для #{@brand.capitalize} #{@model.capitalize}</h2>
      3. Використовуй списки (<ul> або <ol>) для переліків
      4. Довжина тексту: 1500-2500 знаків (компактний формат)
      5. ОБОВ'ЯЗКОВО органічно встав ВСІ надані посилання в текст (кожне посилання тільки ОДИН раз)
      6. Використовуй тільки об'єктивний, технічний стиль викладу. НЕ використовуй особові займенники (я, мені, мій тощо)

      СТРУКТУРА ТЕКСТУ (строго дотримуйся цього порядку):

      1. <h2>Шини для #{@brand.capitalize} #{@model.capitalize}</h2>

      2. Короткий вступ (2-3 речення в тезі <p>):
         - Згадай "шини для #{@brand.capitalize} #{@model.capitalize}"
         #{body_type_ua.present? ? "- Вкажи тип кузова: #{body_type_ua}" : "- Вкажи тип кузова або клас автомобіля (якщо можеш визначити)"}
         - Виділи, що це підбір за параметрами (розміром, сезоном, стилем водіння)

      3. <h3>Типові розміри шин для #{@brand.capitalize} #{@model.capitalize}</h3>
         <p>Короткий опис розмірного ряду (1-2 речення)</p>
         <ul> зі списком усіх наданих розмірів та їхніх особливостей (використовуй усі посилання на розміри)

      4. <h3>Популярні бренди та їхні особливості</h3>
         <p>Інформація про рекомендовані виробники шин для цієї моделі (Bridgestone, Michelin, Continental, Nokian тощо) - коротко, 2-3 речення з згадкою сезонності та типів шин</p>

      5. <h3>Рекомендації щодо підбору шин</h3>
         <ul> або <ol> з 4-5 пунктами:
           <li>Індекси навантаження та швидкості для даної моделі</li>
           <li>Вибір сезонності (літо, зима, всесезонка)</li>
           <li>Малюнок протектора під стиль водіння</li>
           <li>Рекомендований тиск</li>
         </ul>

      6. <h3>Переваги ProKoleso</h3>
         <p>Короткий опис переваг (2-3 речення): широкий вибір, перевірені бренди, доставка, консультація</p>

      7. ФІНАЛЬНИЙ ПАРАГРАФ З CTA (ОБОВ'ЯЗКОВО!):
         <p>ОБОВ'ЯЗКОВО має містити:
         - Фразу "Купити шини на #{@brand.capitalize} #{@model.capitalize}" або "Купити резину на #{@brand.capitalize} #{@model.capitalize}"
         - Завершальну фразу "оформіть замовлення онлайн" (саме ці слова!)

         Приклад: "Купити шини на #{@brand.capitalize} #{@model.capitalize} легко в каталозі ProKoleso. Оберіть відповідний розмір і бренд, отримайте консультацію фахівця та оформіть замовлення онлайн."
         </p>

      СТИЛЬ ВИКЛАДУ:
      - Використовуй безособові конструкції: "Шини характеризуються...", "Модель відрізняється...", "Для #{@brand.capitalize} #{@model.capitalize} рекомендуються..."
      - Уникай займенників "їх", "них", "його", "її"

      ВАЖЛИВО ПО ФОРМАТУ ПОСИЛАНЬ:
      - ЗАВЖДИ використовуй формат: /shiny/w-215/h-55/r-17/
      - НЕПРАВИЛЬНО: /shiny/215/55/r17/ або /shiny/w215/h55/r-17/
      - ПРАВИЛЬНО: /shiny/w-215/h-55/r-17/

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
end
