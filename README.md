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
* /api/v1/json_write_for_read - перенос текстов из lib/template_texts/data.txt в lib/template_texts/data.json
* /api/v1/total_arr_to_table - рерайт текста из lib/template_texts/data.json и запись в базу данных
* /api/v1/total_arr_to_table_sentence - рерайт предложений в заданном а абзаце порядке 
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

// продолжение

### Экспорт данных из таблиц
* /export_text 
* /export_sentence