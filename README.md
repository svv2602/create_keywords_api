# README
Для сборки использовать:
* sudo docker build --build-arg OPENAI_API_KEY=your_openai_api_key -t my-rails-app .

 
где your_openai_api_key - реальный ключ

===================================

Запуск:
* sudo docker run --rm -p 3000:3000 my-rails-app