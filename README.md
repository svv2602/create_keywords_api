# README

Для индексации группы урлов 
* /size_to_index_google - ( размер| +сезонность | +ua) - 8шт
    * Пример запуска с параметрами: /size_to_index_google?w=175&h=70&r=13

Для индексации статьи
* /article_to_index_google - ( ru|ua) - 2шт
    * Пример запуска с параметрами: 
  /article_to_index_google?article="https://prokoleso.ua/ua/info/vse-o-shinah/laufenn-firestone-roadstone-starmaxx-taurus-ta-premiorri-shyny-dlya-zymy-2024-2025/"

Для сборки использовать:
* sudo docker build --build-arg OPENAI_API_KEY=your_openai_api_key -t my-rails-app .

 
где your_openai_api_key - реальный ключ,  сразу после равно, без пробелов и кавычек

===================================

Запуск:
* sudo docker run --rm -p 3000:3000 my-rails-app

====================================
* http://192.168.3.145:3003

endpoint:
* /api/v1/questions  - для блока FAQs легковые шины
* /api/v1/show - внутренняя перелинковка по ключевикам (с параметром ua для украинской версии, без параметра - ru)
  * пример: /api/v1/show?language=ua
* /api/v1/questions_track - для блока FAQs грузовые шины
* /api/v1/questions_diski - для блока FAQs диски
* /api/v1/text_line?url=params_url - текст об ошибках при поиске размера
  * params_url - строка https://prokoleso.ua/shiny/w-175/h-70/r-13/', приведенная к виду: https%3A%2F%2Fprokoleso.ua%2Fshiny%w-175%2Fh-70%2Fr-13%2F



  =================================================
* /api/v1/seo_text?url=params_url - генерация текста под урл (с оптимизацией, заголовками, ошибками, ссылками и html-разметкой)

  Пример запроса:
   легковые:
     curl http://localhost:3000/api/v1/seo_text?url=https%3A%2F%2Fprokoleso.ua%2Fshiny%2Fletnie%2Fkumho%2Fw-175%2Fh-70%2Fr-13%2F
   или без вопросов (add params without_questions=1)
     curl "http://localhost:3000/api/v1/seo_text?without_questions=1&url=https%3A%2F%2Fprokoleso.ua%2Fshiny%2Fletnie%2Fkumho%2Fw-175%2Fh-70%2Fr-13%2F"

   грузовые:
    curl http://localhost:3000/api/v1/seo_text?url=https%3A%2F%2Fprokoleso.ua%2Fgruzovye-shiny%2Fw-385%2Fh-65%2Fr-22.5%2Faxis-pritsepnaya%2Faeolus%2F

================================================= 


## 🤖 AI-система генерации отзывов


* /api/v1/reviews - генерация отзывов по списку шин:
  * значения параметров:
    *  season:  1 - "летние";  2 - "зимние"; 3 - "всесезонные"
    *  type_review:  1 - "положительный";  -1 -  "негативный";  0 -  "нейтральный"

        Пример запроса:
      curl -X POST -H "Content-Type: application/json"      -d '{"tyres": [
          {
            "brand": "michelin",
            "model": "alpin",
            "width": 205,
            "height": 55,
            "diameter": 16,
            "season": 1,
            "type_review": 1,
            "id": "m1"
          },
          {
            "brand": "bridgestone",
            "model": "blizzak",
            "width": 185,
            "height": 60,
            "diameter": 14,
            "season": 2,
            "type_review": -1,
            "id": "m567"
          }
        ]
      }'       http://localhost:3000/api/v1/reviews

       *** localhost:3000 - заменить на рабочий сервер ***

=========================================================



* /api/v1/reviews_for_model - генерация отзывов для модели со списком размеров шин:
  * значения параметров:
    *  season:  1 - "летние";  2 - "зимние"; 3 - "всесезонные"
    *  grade: средняя оценка для группы
    *  number_of_reviews: количество отзывов для группы (размеры выбираются случайным образом)
  
     Пример запроса:
    curl -X POST -H "Content-Type: application/json"      -d '{
      "brand": "hankook",
      "model": "k435",
      "season": 2,
      "grade": 4.0,
      "number_of_reviews": 20,
      "sizes_of_model" : [
        {"width": 205, "height": 55, "diameter": 16, "id": "m1"},
        {"width": 215, "height": 55, "diameter": 16, "id": "m1"},
        {"width": 215, "height": 55, "diameter": 17, "id": "m1"},
        {"width": 175, "height": 70, "diameter": 14, "id": "m22"},
        {"width": 185, "height": 55, "diameter": 15, "id": "m321"},
        {"width": 235, "height": 55, "diameter": 18, "id": "m45"}
      ]
    }'       http://localhost:3000/api/v1/reviews_for_model
  

        *** localhost:3000 - заменить на рабочий сервер ***
  
    =========================================================

## 🤖 AI-система генерации отзывов

### Обзор системы
Новая AI-система объединяет существующий алгоритм с современными технологиями GPT для создания более естественных отзывов.

### Ключевые возможности:
- **GPT-4o-mini** для улучшения качества текста
- **Умная постобработка** для естественности
- **Универсальная постобработка** для уникальности всех отзывов
- **Контекстные эмодзи** вместо случайных
- **Контроль длины** отзывов
- **Гибкие настройки** через Feature Flags

---

## 📚 Документация

Вся документация организована в папке **[`docs/`](docs/)**:

### Быстрый старт:
- 🚀 **[START_HERE.md](START_HERE.md)** - главная точка входа
- ⚡ **[docs/quickstart/DEEPSEEK_QUICKSTART.md](docs/quickstart/DEEPSEEK_QUICKSTART.md)** - полный гайд по DeepSeek

### Руководства:
- 📖 **[docs/guides/AI_REVIEWS_GUIDE.md](docs/guides/AI_REVIEWS_GUIDE.md)** - AI-система генерации отзывов
- 🎯 **[docs/guides/FORCE_MODEL_USAGE.md](docs/guides/FORCE_MODEL_USAGE.md)** - прямое указание AI модели
- 🐳 **[docs/guides/DOCKER_GUIDE.md](docs/guides/DOCKER_GUIDE.md)** - запуск через Docker

### Технические отчеты:
- 📊 **[docs/reports/DEEPSEEK_INTEGRATION_REPORT.md](docs/reports/DEEPSEEK_INTEGRATION_REPORT.md)** - технический отчет о внедрении
- 🔄 **[docs/reports/DEEPSEEK_DEFAULT_CHANGES.md](docs/reports/DEEPSEEK_DEFAULT_CHANGES.md)** - изменения в версии 2.0

---

### Управление системой (create_keywords_api/app/services/feature_flags.rb)

#### Основные команды:
```bash
# Проверить статус системы
rails ai_reviews:status

# Включить AI для 30% пользователей
rails ai_reviews:enable[30]

# Постепенно увеличить процент
rails ai_reviews:gradually_increase

# Протестировать систему
rails ai_reviews:test

# Показать статистику затрат
rails ai_reviews:weekly_stats

# Управление универсальной постобработкой
rails ai_reviews:toggle_universal_processing[true]   # включить
rails ai_reviews:toggle_universal_processing[false]  # выключить

# Экстренно отключить при проблемах
rails ai_reviews:emergency_disable

# Сбросить к настройкам по умолчанию
rails ai_reviews:reset
```

### 💎 DeepSeek интеграция (ПО УМОЛЧАНИЮ ДЛЯ ВСЕХ ЗАДАЧ!)

#### ⚡ DeepSeek используется автоматически:
- ✅ **По умолчанию для ВСЕХ задач** (SEO-тексты, отзывы, премиум контент)
- ✅ **Автоматический fallback на OpenAI** при недоступности
- ✅ **Экономия до 90%** на всех операциях
- ✅ **Качество на уровне GPT-4** (90.8% MMLU)

#### Быстрый старт:
1. Добавьте в `.env`:
```bash
DEEPSEEK_API_KEY=your_deepseek_api_key
```

2. Проверьте статус:
```bash
rails ai_reviews:deepseek_status
```

3. **Готово!** DeepSeek работает автоматически везде.

#### Команды мониторинга:
```bash
# Проверить статус DeepSeek
rails ai_reviews:deepseek_status

# Протестировать API
rails ai_reviews:test_deepseek

# Показать экономию
rails ai_reviews:calculate_savings

# Общий статус AI
rails ai_reviews:status
```

#### 🎯 Прямое указание модели (опционально):

**Ruby:**
```ruby
# DeepSeek по умолчанию
writer = ContentWriter.new
text = writer.write_seo_text(prompt, 1000)

# Принудительно GPT-4o
writer = ContentWriter.new(force_model: 'gpt-4o')
text = writer.write_seo_text(prompt, 1000)
```

**API:**
```bash
curl -X POST http://localhost:3000/api/v1/generate_seo_text \
  -d '{"brand": "Michelin", "force_model": "gpt-4o"}'
```

📚 **Подробнее:** [`docs/guides/FORCE_MODEL_USAGE.md`](docs/guides/FORCE_MODEL_USAGE.md)

#### Льготные часы (в 2 раза дешевле!):
- **UTC:** 16:30-00:30
- **Киев (UTC+2):** 18:30-02:30

#### Сравнение цен (за 1M токенов):
| Модель | Input | Output | Статус |
|--------|-------|--------|--------|
| **DeepSeek** | **$0.27** | **$1.10** | **По умолчанию** ✅ |
| DeepSeek (льготные) | $0.135 | $0.55 | **Скидка 50%** 🔥 |
| GPT-4o | $2.50 | $10.00 | Fallback |

#### Автоматические fallback'и:
- DeepSeek недоступен → OpenAI
- Лимиты превышены → gpt-4o-mini
- Ошибка → повтор с fallback

#### Настройки по умолчанию:
- **AI обработка**: 30% отзывов
- **Постобработка**: 100% AI отзывов получают полную постобработку
- **Универсальная постобработка**: включена (все отзывы проходят обработку для уникальности)
- **Умные эмодзи**: включены
- **Контроль длины**: включен
- **DeepSeek**: используется ПО УМОЛЧАНИЮ для ВСЕХ задач (экономия до 90%) ✅
- **OpenAI**: используется ТОЛЬКО как fallback при недоступности DeepSeek

#### Изменение настроек по умолчанию:
Файл: `app/services/feature_flags.rb`
```ruby
DEFAULTS = {
  ai_processing_percentage: 30,      # 30% отзывов через AI
  post_processing_percentage: 70,    # 70% AI отзывов с постобработкой
  smart_emoji_enabled: true,         # умные эмодзи включены
  length_control_enabled: true,      # контроль длины включен
  hybrid_processing_enabled: true,   # гибридная обработка включена
  force_ai_processing: false         # принудительная AI обработка выключена
}
```

#### Мониторинг затрат:
- Автоматическое отслеживание стоимости AI-запросов
- Дневные лимиты: $200 (production) / $50 (development)
- Автоматическое переключение на fallback при превышении лимитов
- Автоопределение льготных часов DeepSeek для дополнительной экономии
- Детальная статистика по моделям (OpenAI vs DeepSeek)

#### Стратегии обработки:
1. **AI Enhanced**: Полная AI-обработка для сложных отзывов
2. **Hybrid**: Комбинация старых и новых методов
3. **Classic**: Существующий алгоритм без изменений
4. **Universal Processing**: Все отзывы проходят обработку для уникальности с сохранением стиля и длины

### Безопасное внедрение:
1. Начните с 10-15% пользователей
2. Мониторьте качество и затраты
3. Постепенно увеличивайте до желаемого уровня (30-50%)
4. При проблемах используйте `rails ai_reviews:emergency_disable`

    =========================================================

#### Генерация текстов для страниц типа "Шины в {городе}"
* /api/v1/seo_text_city - генерация текста для города с разделом вопросы-ответы
  * language - значения: ru - русский текст; ua - украинский текст
  * city - название города (желательно с учетом выбранного языка)
    
пример: /api/v1/seo_text_city?language=ru&city="Киев"


      =========================================================

#### дополнительно:
* /api/v1/generate_completion - формирование заголовков для статей, созраняются в lib/template_texts/title_h2.json
* /api/v1/total_generate_seo_text - полный запуск всех операций по генерации текстов (json, абзацы, предложения).
  *  В контроллере стоит по 5 операций 
  *  При аварийной остановке обработка продолжается
  *  /total_generate_seo_text?type_proc=1 - При необходимости запустить все с начала необходимо указать параметр type_proc: 
  *  /total_generate_seo_text?all_recods=1 - Генерация предложений заново для всех текстов, без параметра - генерация с момента остановки (или с начала если sentence пуст)

* /api/v1/json_write_for_read - перенос текстов из lib/template_texts/data.txt в lib/template_texts/data.json
* /api/v1/total_arr_to_table - рерайт текста из lib/template_texts/data.json и запись в базу данных (по умолчанию по одному проходу для каждого абзаца)
* /api/v1/total_arr_to_table_sentence - рерайт предложений в заданном а абзаце порядке (по умолчанию по одному проходу для каждого предложения)


#### Важно
* в методе def total_arr_to_table Задаем количество повторов вариантов для всех текстов из data.json, 
для каждого текста генерируются по образцу уникальные абзацы текста и записываются в SeoContentText 
  * number_of_repeats_for_text = 5 - Задаем количество повторов вариантов для всего текста
  * number_of_repeats = 5 - количество вариантов написания каждого абзаца
  
* в методе total_arr_to_table_sentence Задаем количество повторов вариантов для всех текстов из SeoContentText, 
для каждого текста генерируются по образцу уникальные предложения по каждому абзацу и записываются в SeoContentTextSentence 
  * number_of_repeats_for_text = 5 - Задаем количество повторов вариантов для всего текста 
  * number_of_repeats = 5 - количество вариантов написания каждого предложения

/// продолжение

### Экспорт данных из таблиц
* /download_database - Выгрузка базы данных
* /export_text - Экспорт данных в json из SeoContentText
* /export_sentence - Экспорт данных в json из SeoContentTextSentence
* /count_records - количество записей в таблицах 
* /clear_tables_texts c параметром `table`
  * table=1 -  SeoContentText
  * table=2 -  SeoContentTextSentence
  * table=12 - SeoContentText и SeoContentTextSentence

==============================
Импорт
==============================
### Добавление новых брендов 
* Чтобы добавить любые новые бренды в базу данных нужно:
  * в файл lib/brands.xlsx - внести новые бренды (в первом столбике - название для url)
    * в последней колонке указать тир урла (0 - шины, 1- диски)
  * /add_new_brand_entries - выполнить из браузера
  * ВНИМАНИЕ - для вывода популярных брендов в списке вопросов-ответов внести изменения в соответствующий раздел в app/services/constants.rb

### Порядок заливки украинских переводов в базу данных
* После создания русских текстов в SeoContentTextSentence запустить формирование файлов для перевода (контроллер - exports_controller.rb)
  * !!! если необходимо убрать [size] выполнить /replace_size_in_seo_content_text_sentence_r22 # -сделано только для дисков
  * /export_xlsx?max=max_id,
      * где max_id - максимальный номер id с которого начинать новый отсчет записей для выгрузки в папку,
      * выгружается по 30 000 записей (условие для выгрузки  - where("sentence_ua = '' and id < max_id ")
      * выгрузка в папку lib/text_ua/ файл вида - seo_content_text_sentences_1_534_655.xlsx
      * файл импортировать в таблицу google и сделать перевод (=googletranslate(B2;"ru";"uk"))
      * все переводы сохранить в сформированных файлах для дальнейшей обработки
  * запустить 
    * /process_files_ua?proc=1 - для таблицы SeoContentTextSentence
    * в цикле будут обработаны все xlsx-файлы в директории lib/text_ua
    
      
  * Для замены технических переменных на [size] Выполнить
    * replace_text_in_seo_content_text_sentence?proc=1 - для грузовых шин
    * replace_text_in_seo_content_text_sentence?proc=2 - для дисков
    * replace_text_in_seo_content_text_sentence?proc=3 - для дисков (r22)
      
==============================

### Порядок заливки вопросов в базу данных
* Подготовить файл - excel_file = "lib/text_questions/questions_base.xlsx" с вопросами
  * первый столбик содержит только вопросы по необходимой теме
* Запустить /control_question (контроллер - exports_controller.rb)
  * для заполнения таблицы с базовыми вопросами - first_filling_of_table(count, type_paragraph), где
      * count: 0 - для всего файла, или можно ограничить первыми n-записями
      * type_paragraph: 0 - по легковым шинам, 1 - по дискам,  2 - по грузовым шинам
      * опционально можно указать type_season: 1 - вопросы вносятся для первого элемента списка сезон(ось, тип диска)
  * second_filling_of_table(m) , где m - количество проходов AI по базовым вопросам (количество вариантов)
+ /export_questions_to_xlsx - После формирования русских ответов и вопросов выгрузить в excel данные для перевода в Google Translate
* Сохранить переводы в эксельных файлах в lib/text_ua 
 * формат файла - колонки id, Questions_ru, Answer_ru, Questions_ua, Answer_ua
* Выполнить
  * /process_files_ua?proc=2 - для таблицы QuestionsBlock
  * в цикле будут обработаны все xlsx-файлы в директории lib/text_ua


==============================

### Порядок добавления отзывов в базу данных
#### Предварительная подготовка - !!! заполнить один раз !!!
  * /api/v1/fill_table_review - создает параметры в таблицу Review для генерации отзывов  
  * /api/v1/download_car_tire_size_info - первоначальная загрузка базы автомобилей с размерами шин и дисков
    * задействованые таблицы: TestTableCar2Brand, TestTableCar2Model, TestTableCar2Kit, TestTableCar2KitDiskSize, TestTableCar2KitTyreSize
    * /export_for_translit_xlsx - выгрузка данных для транслитерации (указать нужные таблицы) Внимание!!! - запуск без /api/v1/
    * /import_translit_auto - для обновления транслит по брендам и моделям автомобилей для TestTableCar2Brand и TestTableCar2Model
      * !!! подготовленные данные предварительно  сохранить в lib/cars_db/TestTableCar2Brand_ready.xlsx и lib/cars_db/TestTableCar2Model_ready.xlsx
    
    * /import_reviews_without_params - добавление шаблонов отзывов без учета параметров из файла типа "lib/reviews_templates/reviews_for_load.xlsx"

    * /api/v1/create_review_templates - генерация шаблонов отзывов по таблице Review (min..max - диапазон id в Review)
    Раскладка по таблицам (запросы с параметрами):
    countReadyReviews:    # /api/v1/create_review_templates?min=10000&max=20000
    countReadyReviews20:  # /api/v1/create_review_templates?min=20000&max=25000
    countReadyReviews25:  # /api/v1/create_review_templates?min=25000&max=30000
    countReadyReviews30:  # /api/v1/create_review_templates?min=30000&max=35000
    countReadyReviews35:  # /api/v1/create_review_templates?min=35000&max=40000
    countReadyReviews40:  # /api/v1/create_review_templates?min=40000&max=45000
    countReadyReviews45:  # /api/v1/create_review_templates?min=45000&max=50000

    * /copy_ready_reviews_to_main_tab - перенос данных из копий таблиц отзывов в основную таблицу ReadyReviews
    * /control_records_reviews - исправление распространенных ошибок генерации

    * /export_reviews_to_xlsx,
      * где max_id - максимальный номер id с которого начинать новый отсчет записей для выгрузки в папку,
      * выгружается по 20 000 записей (условие для выгрузки  - ReadyReviews.where("review_ua is null ")
      * выгрузка в папку lib/text_reviews_ua файл вида - ready_reviews_6_286.xlsx
      * файл импортировать в таблицу google и сделать перевод (=googletranslate(B2;"ru";"uk"))
      * все переводы сохранить в сформированных файлах для дальнейшей обработки
      * /process_files_ua?proc=3 - для таблицы ReadyReviews
        * в цикле будут обработаны все xlsx-файлы в директории lib/text_reviews_ua (обновление полей с отзывами по id)

===================
### Блок ТОП-модели
* залить данные в таблицу с моделями:
  * создать файл lib/top_models.xlsx
  * выполнить заливку: /add_new_model_entries
* получение данных в json: 
  * для украинской версии - /api/v1/show_models?language=ua
  * для русской - /api/v1/show_models?language=ru или без параметра
* просмотр в html: /api/v1/show_models?html_view=1&language=ua

### Генерация SEO текстов
* **POST** `/api/v1/generate_seo_text` - генерация SEO текста для карточки товара
  * **Параметры:**
    - `tire_description` (string) - описание модели шин с HTML-разметкой
    - `brand` (string) - бренд производителя
    - `model` (string) - модель шины
    - `season` (string) - сезон шин
    - `language` (string) - язык текста (ru/ua)
    - `size` (string) - размер шин
    - `product_id` (integer) - ID товара
    - `load_index` (string) - индекс нагрузки
    - `speed_index` (string) - индекс скорости
    - `seo_requirements` (string, optional) - SEO требования
    - `links` (array, optional) - массив ссылок для органичной вставки в текст
    - `max_tokens` (integer, optional) - максимальное количество токенов (по умолчанию 2000)
  * **Формат ссылок:**
    ```json
    "links": [
      {
        "brand": "/shiny/bridgestone/",
        "model": "/shiny/bridgestone/blizzak-6/",
        "brand_size": "/shiny/bridgestone/w-165/h-65/r-14/",
        "brand_sezon": "/shiny/zimnie/bridgestone/",
        "size": "/shiny//w-165/h-65/r-14/"
      }
    ]
    ```
  * **Пример запроса:**
    ```json
    {
      "tire_description": "<p>Высококачественные летние шины <strong>Michelin Pilot Sport 4</strong> с улучшенными характеристиками сцепления и управляемости.</p>",
      "brand": "Michelin",
      "model": "Pilot Sport 4",
      "season": "летние",
      "language": "ru",
      "size": "225/45 R17",
      "product_id": 952,
      "load_index": "99",
      "speed_index": "H",
      "seo_requirements": "Ключевые слова: Michelin Pilot Sport 4, летние шины 225/45 R17, спортивные шины. Длина: 800-1200 слов.",
      "links": [
        {
          "brand": "/shiny/bridgestone/",
          "model": "/shiny/bridgestone/blizzak-6/",
          "brand_size": "/shiny/bridgestone/w-165/h-65/r-14/",
          "brand_sezon": "/shiny/zimnie/bridgestone/",
          "size": "/shiny//w-165/h-65/r-14/"
        }
      ],
      "max_tokens": 2000
    }
    ```
  * **Ответ:**
    ```json
    {
      "success": true,
      "seo_text": "<h1>Michelin Pilot Sport 4 - Летние шины 225/45 R17</h1>...",
      "product_id": 952,
      "metadata": {
        "brand": "Michelin",
        "model": "Pilot Sport 4",
        "season": "летние",
        "language": "ru",
        "size": "225/45 R17",
        "load_index": "99",
        "speed_index": "H",
        "generated_at": "2024-01-15T10:30:00Z"
      }
    }
    ```

пример запроса:
curl -s -X POST http://localhost:3000/api/v1/generate_seo_text -H "Content-Type: application/json" -d '{
  "tire_description": "<p>Высококачественные зимние шины bridgestone blizzak-6 размером 225/45 R17.</p>",
  "brand": "bridgestone",
  "model": "blizzak-6",
  "season": "зимние", 
  "language": "ru",
  "size": "225/45 R17",
  "product_id": 952,
  "load_index": "99",
  "speed_index": "H",  
  "seo_requirements": "Ключевые слова: bridgestone blizzak-6, зимние шины 225/45 R17",
  "links": [{"brand": "/shiny/bridgestone/","model": "/shiny/bridgestone/blizzak-6/", "brand_sezon": "/shiny/zimnie/bridgestone/"}],
  "max_tokens": 500
}'


=========================================================