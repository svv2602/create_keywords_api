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

    # Генерация текста через AI (увеличиваем max_tokens для более длинного текста)
    # 8000 токенов = примерно 6000 слов = 24000-32000 символов (с запасом для украинского)
    response = ContentWriter.new.write_seo_text(prompt, 8000)

    if response
      text = response['choices'][0]['message']['content'].strip
      text = clean_html_text(text)

      # Нормализуем украинский текст (заменяем латиницу на кириллицу)
      text = normalize_ukrainian_text(text) if @language == 'ua'

      # Проверка на обрезанный текст
      cta_phrases = @language == 'ru' ?
        ['оформите заказ онлайн', 'оформіть замовлення онлайн'] :
        ['оформіть замовлення онлайн', 'оформите заказ онлайн']

      # Проверка целостности текста
      unless text_complete?(text, required_phrases: cta_phrases)
        log_incomplete_text_warning("#{@brand} #{@model} (#{@language})")
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
      'B' => 'В', 'b' => 'в'
    }

    # Заменяем только в словах (не в HTML-тегах и атрибутах)
    # Разбиваем на теги и текст
    parts = text.split(/(<[^>]+>)/)

    parts.map do |part|
      # Если это не HTML-тег, нормализуем
      if !part.start_with?('<')
        # Заменяем латинские буквы на кириллические, но только если они окружены кириллицей
        normalized = part.dup
        latin_to_cyrillic.each do |latin, cyrillic|
          # Заменяем латинскую букву, если рядом есть кириллица
          normalized.gsub!(/([а-яіїєґА-ЯІЇЄҐ])#{Regexp.escape(latin)}([а-яіїєґА-ЯІЇЄҐ])/) do
            "#{$1}#{cyrillic}#{$2}"
          end
          # Заменяем в начале слова если после идет кириллица
          normalized.gsub!(/\b#{Regexp.escape(latin)}([а-яіїєґА-ЯІЇЄҐ])/) do
            "#{cyrillic}#{$1}"
          end
          # Заменяем в конце слова если перед идет кириллица
          normalized.gsub!(/([а-яіїєґА-ЯІЇЄҐ])#{Regexp.escape(latin)}\b/) do
            "#{$1}#{cyrillic}"
          end
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
      4. Длина текста: 2500-3500 знаков (для популярных моделей до 4000)
      5. ОБЯЗАТЕЛЬНО органично вставь ВСЕ предоставленные ссылки в текст (каждую ссылку только ОДИН раз)
      6. Используй только объективный, технический стиль изложения. НЕ используй личные местоимения (я, мне, мой и т.д.)

      СТРУКТУРА ТЕКСТА (строго следуй этому порядку):

      1. <h2>Шины для #{@brand.capitalize} #{@model.capitalize}</h2>

      2. Краткое вступление (2-3 предложения в теге <p>):
         - Упомяни "шины для #{@brand.capitalize} #{@model.capitalize}"
         #{@body_type.present? ? "- Укажи тип кузова: #{@body_type}" : "- Укажи тип кузова или класс автомобиля (если можешь определить)"}
         - Выдели, что это подбор по параметрам (размеру, сезону, стилю вождения)

         Пример: "Если вы ищете подходящие шины для #{@brand.capitalize} #{@model.capitalize}, на этой странице вы найдете варианты, идеально подходящие по размеру, сезону и стилю вождения."

      3. <h3>Типичные размеры шин для #{@brand.capitalize} #{@model.capitalize}</h3>
         <p>Рассказ о типичных размерах шин (#{@typical_sizes.join(', ')}) с органичной вставкой ссылок на размеры.</p>
         <ul> со списком размеров и их особенностями (с использованием предоставленных ссылок)

      4. <h3>Сезонность шин</h3>
         <p>Вступительный параграф о вариантах сезонности</p>
         <h4>Летние шины</h4>
         <p>Описание летних шин...</p>
         <h4>Зимние шины</h4>
         <p>Описание зимних шин...</p>
         <h4>Всесезонные шины</h4>
         <p>Описание всесезонных шин...</p>

      5. <h3>Популярные бренды шин</h3>
         <p>Информация о рекомендуемых производителях шин для этой модели (Bridgestone, Michelin, Continental, Nokian и др.)</p>
         <ul> список популярных брендов с кратким описанием каждого

      6. <h3>Советы по выбору шин</h3>
         <p>Вступление к советам</p>
         <ul> или <ol>
           <li>Индексы нагрузки и скорости</li>
           <li>Рекомендуемое давление в шинах</li>
           <li>Рисунок протектора</li>
           <li>Другие важные параметры</li>
         </ul>

      7. <h3>Преимущества подбора на сайте ProKoleso</h3>
         <p>Краткое описание преимуществ магазина</p>
         <ul>
           <li>Удобные фильтры по параметрам</li>
           <li>Доставка по всей стране</li>
           <li>Разнообразные формы оплаты и покупка в кредит</li>
           <li>Гарантия качества</li>
           <li>Только проверенные бренды</li>
           <li>Профессиональная консультация</li>
         </ul>

      8. Заключение / CTA (2-3 предложения в теге <p>):
         - ОБЯЗАТЕЛЬНО использовать фразы "Купить шины на #{@brand.capitalize} #{@model.capitalize}" и "Купить резину на #{@brand.capitalize} #{@model.capitalize}" (по одному разу каждую)
         - Завершить призывом: "Выберите шины для #{@brand.capitalize} #{@model.capitalize} в нашем каталоге и оформите заказ онлайн."

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
      4. Довжина тексту: 2500-3500 знаків (для популярних моделей до 4000)
      5. ОБОВ'ЯЗКОВО органічно встав ВСІ надані посилання в текст (кожне посилання тільки ОДИН раз)
      6. Використовуй тільки об'єктивний, технічний стиль викладу. НЕ використовуй особові займенники (я, мені, мій тощо)

      СТРУКТУРА ТЕКСТУ (строго дотримуйся цього порядку):

      1. <h2>Шини для #{@brand.capitalize} #{@model.capitalize}</h2>

      2. Короткий вступ (2-3 речення в тезі <p>):
         - Згадай "шини для #{@brand.capitalize} #{@model.capitalize}"
         #{body_type_ua.present? ? "- Вкажи тип кузова: #{body_type_ua}" : "- Вкажи тип кузова або клас автомобіля (якщо можеш визначити)"}
         - Виділи, що це підбір за параметрами (розміром, сезоном, стилем водіння)

         Приклад: "Якщо ви шукаєте відповідні шини для #{@brand.capitalize} #{@model.capitalize}, на цій сторінці ви знайдете варіанти, ідеально підходящі за розміром, сезоном та стилем водіння."

      3. <h3>Типові розміри шин для #{@brand.capitalize} #{@model.capitalize}</h3>
         <p>Розповідь про типові розміри шин (#{@typical_sizes.join(', ')}) з органічною вставкою посилань на розміри.</p>
         <ul> зі списком розмірів та їхніх особливостей (з використанням наданих посилань)

      4. <h3>Сезонність шин</h3>
         <p>Вступний параграф про варіанти сезонності</p>
         <h4>Літні шини</h4>
         <p>Опис літніх шин...</p>
         <h4>Зимові шини</h4>
         <p>Опис зимових шин...</p>
         <h4>Всесезонні шини</h4>
         <p>Опис всесезонних шин...</p>

      5. <h3>Популярні бренди шин</h3>
         <p>Інформація про рекомендовані виробники шин для цієї моделі (Bridgestone, Michelin, Continental, Nokian тощо)</p>
         <ul> список популярних брендів з коротким описом кожного

      6. <h3>Поради щодо вибору шин</h3>
         <p>Вступ до порад</p>
         <ul> або <ol>
           <li>Індекси навантаження та швидкості</li>
           <li>Рекомендований тиск в шинах</li>
           <li>Малюнок протектора</li>
           <li>Інші важливі параметри</li>
         </ul>

      7. <h3>Переваги підбору на сайті ProKoleso</h3>
         <p>Короткий опис переваг магазину</p>
         <ul>
           <li>Зручні фільтри за параметрами</li>
           <li>Доставка по всій країні</li>
           <li>Різноманітні форми оплати та покупка в кредит</li>
           <li>Гарантія якості</li>
           <li>Тільки перевірені бренди</li>
           <li>Професійна консультація</li>
         </ul>

      8. Висновок / CTA (2-3 речення в тезі <p>):
         - ОБОВ'ЯЗКОВО використовувати фрази "Купити шини на #{@brand.capitalize} #{@model.capitalize}" та "Купити резину на #{@brand.capitalize} #{@model.capitalize}" (по одному разу кожну)
         - Завершити закликом: "Оберіть шини для #{@brand.capitalize} #{@model.capitalize} в нашому каталозі та оформіть замовлення онлайн."

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
