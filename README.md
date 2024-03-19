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
* /api/v1/json_write_for_read - перенос текстов из lib/template_texts/data.txt в lib/template_texts/data.json
* /api/v1/total_arr_to_table - рерайт текста из lib/template_texts/data.json и запись в базу данных
* /api/v1/total_arr_to_table_sentence - рерайт предложений в заданном а абзаце порядке 
