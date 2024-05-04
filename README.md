# README
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
* /api/v1/show - внутренняя перелинковка по ключевикам
* /api/v1/questions_track - для блока FAQs грузовые шины
* /api/v1/questions_diski - для блока FAQs диски
* /api/v1/text_line?url=params_url - текст об ошибках при поиске размера
  * params_url - строка https://prokoleso.ua/shiny/w-175/h-70/r-13/', приведенная к виду: https%3A%2F%2Fprokoleso.ua%2Fshiny%w-175%2Fh-70%2Fr-13%2F

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
* /api/v1/seo_text?url=params_url - генерация текста под урл (с оптимизацией, заголовками, ошибками, ссылками и html-разметкой)

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
  * table=1 -  SeoContentText.delete_all
  * table=2 -  SeoContentTextSentence.delete_all 
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