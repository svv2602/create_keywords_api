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