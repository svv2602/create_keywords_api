# app/services/seo_text_generator.rb

class SeoTextGenerator
    include StringProcessing
    include TextOptimization
    include TextCompletenessValidation
    include HtmlSanitization
  
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
    # Фиксированный лимит токенов для предотвращения обрезания
    # 4000 токенов (×4 = 16000 для Gemini thinking) — запас для thinking + текст 4-5k символов
    # Длина текста контролируется промптом, а не max_tokens
    @max_tokens = 4000
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

        # Быстрая починка HTML перед проверкой целостности
        generated_text = fix_html_ending(generated_text)
        generated_text = fix_unbalanced_tags(generated_text)

        # Проверка целостности сгенерированного текста
        unless text_complete?(generated_text)
          log_incomplete_text_warning("#{@brand} #{@model} #{@size} (#{@language})")
          Rails.logger.warn "Text appears incomplete, attempting to complete it..."

          # Пытаемся автоматически завершить обрезанный текст
          completed_text = complete_truncated_text(generated_text)
          completed_text = fix_html_ending(completed_text) if completed_text
          completed_text = fix_unbalanced_tags(completed_text) if completed_text

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
      8. #{@language == 'ua' ? 'Довжина тексту: 4000-5000 символів. Не перевищуй 5000 символів — це жорстке обмеження.' : 'Длина текста: 4000-5000 символов. Не превышай 5000 символов — это жёсткое ограничение.'}
      9. #{@language == 'ua' ? 'ОБОВ\'ЯЗКОВО органічно встав ВСІ надані посилання в текст (кожне посилання тільки ОДИН раз)' : 'ОБЯЗАТЕЛЬНО органично вставь ВСЕ предоставленные ссылки в текст (каждую ссылку только ОДИН раз)'}
      10. #{@language == 'ua' ? 'ВАЖЛИВО: Використовуй тільки об\'єктивний, технічний стиль викладу. НЕ використовуй особові займенники (я, мені, мій, мій досвід, я тестував, хочу відзначити тощо). Пиши від третьої особи в нейтральному тоні.' : 'ВАЖНО: Используй только объективный, технический стиль изложения. НЕ используй личные местоимения (я, мне, мой, мой опыт, я тестировал, хочу отметить и т.д.). Пиши от третьего лица в нейтральном тоне.'}
      11. #{@language == 'ua' ? 'Фокус на технічних характеристиках, перевагах та застосуванні шин без особистих оцінок та суб\'єктивних думок.' : 'Фокус на технических характеристиках, преимуществах и применении шин без личных оценок и субъективных мнений.'}

      #{@language == 'ua' ? 'АБСОЛЮТНА ЗАБОРОНА - НЕ ПИШИ ПРО ЦЕ (якщо напишеш - текст буде відхилено):' : 'АБСОЛЮТНЫЙ ЗАПРЕТ - НЕ ПИШИ ОБ ЭТОМ (если напишешь - текст будет отклонен):'}
      #{@language == 'ua' ? 'ЗАБОРОНЕНІ СЛОВА та теми, які НЕ можна згадувати НІКОЛИ:' : 'ЗАПРЕЩЕННЫЕ СЛОВА и темы, которые НЕЛЬЗЯ упоминать НИКОГДА:'}
      - #{@language == 'ua' ? 'доставк* (будь-яка форма слова)' : 'доставк* (любая форма слова)'}
      - #{@language == 'ua' ? 'гарант* (будь-яка форма слова)' : 'гарант* (любая форма слова)'}
      - #{@language == 'ua' ? 'акці*, знижк*, спеціальн* пропозиці*' : 'акци*, скид*, специальн* предложени*'}
      - #{@language == 'ua' ? 'ціна, вартість, грн, гривень, коштує' : 'цена, стоимость, грн, гривен, стоит'}
      - #{@language == 'ua' ? 'оплат* (будь-яка форма слова)' : 'оплат* (любая форма слова)'}
      - #{@language == 'ua' ? 'шиномонтаж*, балансир*, балансув*, встановлення' : 'шиномонтаж*, балансир*, балансир*, установк*'}
      - #{@language == 'ua' ? 'наявність, склад, є в наявності' : 'наличие, склад, есть в наличии'}
      - #{@language == 'ua' ? 'повернення, обмін, претензі*' : 'возврат, обмен, претензи*'}
      - #{@language == 'ua' ? 'безкоштовн*, день*, курє*' : 'бесплатн*, день*, курьер*'}
      - #{@language == 'ua' ? 'по телефону, замовити по телефону, дзвоніть' : 'по телефону, заказать по телефону, звоните'}
      - #{@language == 'ua' ? 'через кошик, кошик сайту' : 'через корзину, корзина сайта'}
      - #{@language == 'ua' ? 'консультант*, консультаці*' : 'консультант*, консультаци*'}
      - #{@language == 'ua' ? 'професійн* консультаці*' : 'профессиональн* консультаци*'}

      #{@language == 'ua' ? 'Пиши ВИКЛЮЧНО про ТЕХНІЧНІ АСПЕКТИ шин:' : 'Пиши ИСКЛЮЧИТЕЛЬНО о ТЕХНИЧЕСКИХ АСПЕКТАХ шин:'}
      - #{@language == 'ua' ? 'Технічні характеристики моделі (ТІЛЬКИ ті, що надані в описі вище)' : 'Технические характеристики модели (ТОЛЬКО те, что даны в описании выше)'}
      - #{@language == 'ua' ? 'Особливості конструкції протектора' : 'Особенности конструкции протектора'}
      - #{@language == 'ua' ? 'Технології виробництва (ТІЛЬКИ якщо згадані в описі)' : 'Технологии производства (ТОЛЬКО если упомянуты в описании)'}
      - #{@language == 'ua' ? 'Переваги для різних дорожніх умов' : 'Преимущества для разных дорожных условий'}
      - #{@language == 'ua' ? 'Рекомендовані типи автомобілів' : 'Рекомендованные типы автомобилей'}
      - #{@language == 'ua' ? 'Сезонність використання' : 'Сезонность использования'}

      #{@language == 'ua' ? 'ПРАВИЛА ФОРМАТУВАННЯ:' : 'ПРАВИЛА ФОРМАТИРОВАНИЯ:'}
      - #{@language == 'ua' ? 'НЕ виділяй жирним (<strong>) текст в заголовках H2, H3, H4' : 'НЕ выделяй жирным (<strong>) текст в заголовках H2, H3, H4'}
      - #{@language == 'ua' ? 'НЕ використовуй вкладені теги <strong><strong></strong></strong>' : 'НЕ используй вложенные теги <strong><strong></strong></strong>'}
      - #{@language == 'ua' ? 'НЕ виділяй жирним текст всередині посилань <a>' : 'НЕ выделяй жирным текст внутри ссылок <a>'}
      - #{@language == 'ua' ? 'НЕ дублюй інформацію - кожен факт згадуй тільки один раз' : 'НЕ дублируй информацию - каждый факт упоминай только один раз'}
      - #{@language == 'ua' ? 'ЗАБОРОНЕНО використовувати ієрогліфи, символи китайської, японської, корейської та інших східноазіатських мов. Використовуй ТІЛЬКИ кирилицю та латиницю!' : 'ЗАПРЕЩЕНО использовать иероглифы, символы китайского, японского, корейского и других восточноазиатских языков. Используй ТОЛЬКО кириллицу и латиницу!'}

      #{@language == 'ua' ? 'СТРУКТУРА ТЕКСТУ:' : 'СТРУКТУРА ТЕКСТА:'}
      - H2: #{@language == 'ua' ? 'основний заголовок з брендом, моделлю та розміром' : 'основной заголовок с брендом, моделью и размером'}
      - H3: #{@language == 'ua' ? '3-4 підзаголовки за темами (характеристики, переваги, застосування, вибір)' : '3-4 подзаголовка по темам (характеристики, преимущества, применение, выбор)'}
      - #{@language == 'ua' ? 'Абзаци з детальною інформацією та органічно вставленими посиланнями' : 'Абзацы с подробной информацией и органично вставленными ссылками'}
      - #{@language == 'ua' ? 'Марковані списки для ключових особливостей' : 'Маркированные списки для ключевых особенностей'}
      - #{@language == 'ua' ? 'ЗАВЕРШЕННЯ ТЕКСТУ: Одне коротке речення без заголовка з фразою "оформити замовлення онлайн".' : 'ЗАВЕРШЕНИЕ ТЕКСТА: Одно краткое предложение без заголовка с фразой "оформить заказ онлайн".'}
        #{@language == 'ua' ?
          'ТОЧНА формулювання завершального речення (використовуй ТОЧНО одну з цих трьох варіантів):
          1) "Підібрати шини #{@brand} #{@model} #{@size} в каталозі та оформити замовлення онлайн можна на ProKoleso.ua"
          2) "Вибрати та купити шини #{@brand} #{@model} #{@size} можна в інтернет-магазині ProKoleso - оформіть замовлення онлайн"
          3) "Підберіть шини #{@brand} #{@model} #{@size} в каталозі ProKoleso та оформіть замовлення онлайн"

          КАТЕГОРИЧНО ЗАБОРОНЕНО додавати будь-що інше:
          - НЕ додавай "через кошик"
          - НЕ додавай "по телефону"
          - НЕ додавай "консультант допоможе"
          - НЕ додавай "достатньо вибрати"
          - НЕ додавай інформацію про доставку
          - НЕ додавай інформацію про оплату
          - НЕ додавай інформацію про сервіс
          Використовуй ТІЛЬКИ один з трьох варіантів вище - ТОЧНО як написано!' :
          'ТОЧНАЯ формулировка заключительного предложения (используй ТОЧНО один из этих трёх вариантов):
          1) "Подобрать шины #{@brand} #{@model} #{@size} в каталоге и оформить заказ онлайн можно на ProKoleso.ua"
          2) "Выбрать и купить шины #{@brand} #{@model} #{@size} можно в интернет-магазине ProKoleso - оформите заказ онлайн"
          3) "Подберите шины #{@brand} #{@model} #{@size} в каталоге ProKoleso и оформите заказ онлайн"

          КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО добавлять что-либо ещё:
          - НЕ добавляй "через корзину"
          - НЕ добавляй "по телефону"
          - НЕ добавляй "консультант поможет"
          - НЕ добавляй "достаточно выбрать"
          - НЕ добавляй информацию о доставке
          - НЕ добавляй информацию об оплате
          - НЕ добавляй информацию о сервисе
          Используй ТОЛЬКО один из трёх вариантов выше - ТОЧНО как написано!'
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

      #{build_geographic_restrictions}

      #{@language == 'ua' ? 'ВАЖЛИВО: Кожне посилання зі списку використовуй ТІЛЬКИ ОДИН РАЗ в тексті, вставляючи їх органічно в відповідний контекст. НЕ створюй вкладені посилання!' : 'ВАЖНО: Каждую ссылку из списка используй ТОЛЬКО ОДИН РАЗ в тексте, вставляя их органично в соответствующий контекст. НЕ создавай вложенные ссылки!'}

      #{@language == 'ua' ?
        'КРИТИЧНІ ПРАВИЛА HTML ТА URL (ПОРУШЕННЯ = БРАК):
      1. HTML-теги пиши ТІЛЬКИ латиницею: <li>, </li>, <p>, </p>, <ul>, </ul>, <h2>, <a href="...">.
         ЗАБОРОНЕНО: <лі>, </лі>, <п>, <!--ли-->, <!--лi-->. Кирилиця в іменах тегів НЕПРИПУСТИМА!
      2. URL-адреси пиши ТІЛЬКИ латиницею та цифрами. Використовуй ТІЛЬКИ надані посилання БЕЗ змін.
         ЗАБОРОНЕНО створювати свої URL з кирилицею: /шини/, /я/, /ya/, /cxини/, /в-205/, /н-55/, /р-16/.
         ПРАВИЛЬНО: /shiny/, /ua/, w-, h-, r- — тільки латиниця!
      3. Для української версії сайту префікс ТІЛЬКИ /ua/, НІКОЛИ /ya/, /я/ або інші варіанти.
      4. НЕ вставляй &nbsp; між тегами або всередині посилань. НЕ генеруй порожні теги <p>&nbsp;</p>.
      5. НЕ СТВОРЮЙ НОВІ ПОСИЛАННЯ — використовуй ТІЛЬКИ ті href, які надані вище. Якщо посилання не надано — пиши текст без посилання.
      6. ЗАБОРОНЕНО вставляти пробіли всередині URL-адрес: /shiny/w-245/h-40/r-19/, а НЕ /shiny /w -245 /h -40 /r -19/' :
        'КРИТИЧЕСКИЕ ПРАВИЛА HTML И URL (НАРУШЕНИЕ = БРАК):
      1. HTML-теги пиши ТОЛЬКО латиницей: <li>, </li>, <p>, </p>, <ul>, </ul>, <h2>, <a href="...">.
         ЗАПРЕЩЕНО: <лі>, </лі>, <п>, <!--ли-->, <!--лi-->. Кириллица в именах тегов НЕДОПУСТИМА!
      2. URL-адреса пиши ТОЛЬКО латиницей и цифрами. Используй ТОЛЬКО предоставленные ссылки БЕЗ изменений.
         ЗАПРЕЩЕНО создавать свои URL с кириллицей: /шины/, /я/, /ya/, /cxины/, /в-205/, /н-55/, /р-16/.
         ПРАВИЛЬНО: /shiny/, /ua/, w-, h-, r- — только латиница!
      3. Для украинской версии сайта префикс ТОЛЬКО /ua/, НИКОГДА /ya/, /я/ или другие варианты.
      4. НЕ вставляй &nbsp; между тегами или внутри ссылок. НЕ генерируй пустые теги <p>&nbsp;</p>.
      5. НЕ СОЗДАВАЙ НОВЫЕ ССЫЛКИ — используй ТОЛЬКО те href, которые предоставлены выше. Если ссылка не предоставлена — пиши текст без ссылки.
      6. ЗАПРЕЩЕНО вставлять пробелы внутри URL-адресов: /shiny/w-245/h-40/r-19/, а НЕ /shiny /w -245 /h -40 /r -19/'
      }

      #{@language == 'ua' ? '!!! ФІНАЛЬНА ПЕРЕВІРКА ПЕРЕД ГЕНЕРАЦІЄЮ !!!' : '!!! ФИНАЛЬНАЯ ПРОВЕРКА ПЕРЕД ГЕНЕРАЦИЕЙ !!!'}
      #{@language == 'ua' ? 'Перед тим як повернути текст, перевір що в ньому НЕМАЄ:' : 'Перед тем как вернуть текст, проверь что в нём НЕТ:'}
      - #{@language == 'ua' ? 'слів про доставку, гарантію, акції, ціни' : 'слов о доставке, гарантии, акциях, ценах'}
      - #{@language == 'ua' ? 'слів про оплату, шиномонтаж, консультації' : 'слов об оплате, шиномонтаже, консультациях'}
      - #{@language == 'ua' ? 'фраз "через кошик", "по телефону", "зателефонувати"' : 'фраз "через корзину", "по телефону", "позвонить"'}
      - #{@language == 'ua' ? 'фраз про терміни доставки, регіони доставки' : 'фраз о сроках доставки, регионах доставки'}
      #{@language == 'ua' ? 'Якщо знайдеш такі слова - ВИДАЛИ їх повністю!' : 'Если найдёшь такие слова - УДАЛИ их полностью!'}

      #{@language == 'ua' ? 'Поверни тільки HTML-код без додаткових коментарів.' : 'Верни только HTML-код без дополнительных комментариев.'}
    PROMPT
  end
  
  def format_generated_text(text)
    # Общая постобработка HTML (из HtmlSanitization concern)
    text = sanitize_llm_html(text)

    # Специфичные для SeoTextGenerator фиксы
    text = fix_tire_size_links(text)
    text = remove_forbidden_content(text)
    text = fix_cta_link_wrapping(text)

    # Повторная дедупликация после fix_tire_size_links (может создавать новые совпадения)
    text = deduplicate_links(text)

    text
  end

  # Удаляет параграфы с запрещёнными словами о доставке, оплате и т.д.
  def remove_forbidden_content(text)
    # Список запрещённых слов (регулярные выражения для точного поиска)
    # \b - граница слова, чтобы "цінують" не считалось как "ціна"
    forbidden_patterns = if @language == 'ua'
      [
        /\bдоставк/i, /\bгарант/i, /\bакці[ійяює]/i, /\bзнижк/i,
        /\bціна\b/i, /\bцін[аиую]/i, /\bвартість/i, /\bгрн\b/i, /\bгривен/i, /\bкоштує/i,
        /\bоплат/i, /\bшиномонтаж/i, /\bбалансир/i, /\bбалансув/i, /\bвстановлення/i,
        /\bнаявність/i, /\bсклад[іу]/i, /є в наявності/i,
        /\bповернення/i, /\bобмін/i, /\bпретензі/i,
        /\bбезкоштовн/i, /\bкур['є]р/i,
        /по телефон/i, /замовити по телефон/i, /дзвоніт/i,
        /через кошик/i, /кошик сайт/i, /корзин/i,
        /\bконсультант/i, /\bконсультаці/i,
        /професійн.*консультаці/i
      ]
    else
      [
        /\bдоставк/i, /\bгарант/i, /\bакци[ийяю]/i, /\bскид/i,
        /\bцена\b/i, /\bценов/i, /\bстоимост/i, /\bгрн\b/i, /\bгривен/i, /\bстоит\b/i,
        /\bоплат/i, /\bшиномонтаж/i, /\bбалансир/i, /\bустановк/i,
        /\bналичи/i, /\bсклад[еу]/i, /есть в наличии/i,
        /\bвозврат/i, /\bобмен/i, /\bпретензи/i,
        /\bбесплатн/i, /\bкурьер/i,
        /по телефон/i, /заказать по телефон/i, /звонит/i,
        /через корзин/i, /корзина сайт/i, /корзин[аеу]/i,
        /\bконсультант/i, /\bконсультаци/i,
        /профессиональн.*консультаци/i
      ]
    end

    # Разбиваем текст на HTML-элементы (заголовки, параграфы, списки)
    # Паттерн ловит: <h2>...</h2>, <h3>...</h3>, <h4>...</h4>, <p>...</p>, <ul>...</ul>, <ol>...</ol>
    elements = text.scan(/<(?:h[234]|p|ul|ol)>.*?<\/(?:h[234]|p|ul|ol)>/m)

    # Оставляем только последний параграф с CTA (если он правильный)
    cta_phrases = @language == 'ua' ?
      ['оформіть замовлення онлайн', 'оформити замовлення онлайн'] :
      ['оформите заказ онлайн', 'оформить заказ онлайн']

    # Фильтруем элементы, сохраняя только один CTA
    cleaned_elements = []
    valid_cta_element = nil  # Сохраняем последний валидный CTA

    elements.each do |element|
      element_text = element.downcase

      # Заголовки всегда оставляем (они не содержат коммерческой инфы)
      if element.match?(/^<h[234]>/i)
        cleaned_elements << element
        next
      end

      # Списки всегда оставляем (обычно это технические характеристики)
      if element.match?(/^<(?:ul|ol)>/i)
        cleaned_elements << element
        next
      end

      # Проверяем параграфы на запрещённый контент
      if element.match?(/^<p>/i)
        # Проверяем, это CTA параграф?
        is_cta = cta_phrases.any? { |phrase| element_text.include?(phrase) }

        if is_cta
          # Проверяем, что CTA параграф не содержит запрещённых слов
          has_forbidden = forbidden_patterns.any? { |pattern| element_text.match?(pattern) }

          if !has_forbidden
            # Это правильный CTA - сохраняем как кандидат (перезаписываем предыдущий)
            if valid_cta_element
              Rails.logger.info "Replaced duplicate CTA paragraph"
            end
            valid_cta_element = element
          else
            # CTA с запрещёнными словами - пропускаем
            Rails.logger.warn "Removed CTA paragraph with forbidden words: #{element.truncate(100)}"
          end
        else
          # Обычный параграф - проверяем на запрещённые слова
          has_forbidden = forbidden_patterns.any? { |pattern| element_text.match?(pattern) }

          if !has_forbidden
            cleaned_elements << element
          else
            Rails.logger.warn "Removed paragraph with forbidden words: #{element.truncate(100)}"
          end
        end
      end
    end

    # Добавляем CTA в конец (только один)
    if valid_cta_element
      cleaned_elements << valid_cta_element
    else
      # Если валидного CTA нет - добавляем стандартный
      standard_cta = if @language == 'ua'
        "<p>Підберіть шини #{@brand} #{@model} #{@size} в каталозі ProKoleso та оформіть замовлення онлайн.</p>"
      else
        "<p>Подберите шины #{@brand} #{@model} #{@size} в каталоге ProKoleso и оформите заказ онлайн.</p>"
      end
      cleaned_elements << standard_cta
      Rails.logger.info "Added standard CTA paragraph"
    end

    # Объединяем очищенные элементы
    cleaned_elements.join
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


  # Если текст не заканчивается на </p>, оборачиваем хвост в <p>...</p>
  def fix_html_ending(text)
    return text if text.blank?
    stripped = text.strip
    return stripped if stripped.end_with?('</p>') || stripped.end_with?('</ul>') || stripped.end_with?('</ol>')

    # Находим последний закрывающий тег блочного элемента
    last_block_end = [
      stripped.rindex('</p>'),
      stripped.rindex('</ul>'),
      stripped.rindex('</ol>'),
      stripped.rindex('</table>')
    ].compact.max

    if last_block_end
      trailing = stripped[(last_block_end + 4)..].to_s.strip  # +4 для длины "</p>"
      # Подстраховка: вычисляем точную длину закрывающего тега
      after_tag = stripped[last_block_end..]
      tag_end = after_tag.index('>') + 1
      trailing = stripped[(last_block_end + tag_end)..].to_s.strip

      if trailing.length > 5
        Rails.logger.info "fix_html_ending: wrapping trailing text (#{trailing.length} chars) in <p>"
        return stripped[0...(last_block_end + tag_end)] + "\n\n<p>#{trailing}</p>"
      end
    end

    # Текст совсем без блочных тегов — оборачиваем целиком
    stripped
  end

  # Исправляет небаланс HTML-тегов (off-by-one от LLM)
  def fix_unbalanced_tags(text)
    return text if text.blank?

    %w[p li ul ol h2 h3 h4].each do |tag|
      opening = text.scan(/<#{tag}(?:\s[^>]*)?>/).count
      closing = text.scan(/<\/#{tag}>/).count

      if opening > closing
        # Не хватает закрывающих — добавляем в конец
        (opening - closing).times { text = text + "</#{tag}>" }
        Rails.logger.info "fix_unbalanced_tags: added #{opening - closing} missing </#{tag}>"
      elsif closing > opening
        # Лишние закрывающие — убираем последние лишние
        excess = closing - opening
        excess.times { text = text.sub(/<\/#{tag}>\s*\z/, '') }
        Rails.logger.info "fix_unbalanced_tags: removed #{excess} extra </#{tag}>"
      end
    end

    text
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
    sanitize_llm_html(merged)
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
    ]

    # Если URL соответствует валидному паттерну - не подозрительный
    return false if valid_patterns.any? { |p| href.match?(p) }

    # Проверяем, есть ли бренд в URL
    brand_in_url = extract_brand_slug_from_url(href)
    return false if brand_in_url && Brand.exists?(url: "/shiny/#{brand_in_url}/")

    # URL содержит /shiny/something/ но не соответствует известным паттернам
    href.match?(/\/shiny\/[^\/]+\/?$/)
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
    if normalized =~ /(\d{3})\/(\d{2})r(\d{2})(c?)/i
      width, height, radius, commercial = $1, $2, $3, $4

      return nil unless valid_tire_dimensions?(width, height, radius)

      # Определяем языковой префикс из оригинального href или из настроек
      lang_prefix = if original_href.include?('/ua/')
                      '/ua'
                    elsif @language == 'ua'
                      '/ua'
                    else
                      ''
                    end

      "#{lang_prefix}/shiny/w-#{width}/h-#{height}/r-#{radius}#{commercial.downcase}/"
    else
      nil
    end
  end

  def valid_tire_dimensions?(width, height, radius)
    w, h, r = width.to_i, height.to_i, radius.to_i
    # Ширина: 125-355, Профиль: 0-85, Радиус: 12-24
    w >= 125 && w <= 355 && h >= 0 && h <= 85 && r >= 12 && r <= 24
  end

  # Исправляет CTA-параграф: если в последнем <p> есть ссылка с анкором-предложением
  # (>60 символов), разворачивает её в plain text.
  def fix_cta_link_wrapping(text)
    return text if text.blank?

    last_p_match = text.match(/.*(<p>.*?<\/p>)\s*\z/im)
    return text unless last_p_match

    last_p = last_p_match[1]
    fixed_p = last_p.gsub(/<a\s+[^>]*href="[^"]*"[^>]*>(.*?)<\/a>/im) do
      anchor = $1
      plain_anchor = anchor.gsub(/<[^>]+>/, '')
      if plain_anchor.length > 60
        Rails.logger.info "Fix CTA wrapping: unwrapped long anchor (#{plain_anchor.length} chars): \"#{plain_anchor.truncate(80)}\""
        anchor
      else
        $&
      end
    end

    text.sub(last_p, fixed_p)
  end

  private
  end