FROM ruby:3.3.8
# В параметрах сборки укажите API-ключи
ARG OPENAI_API_KEY
ARG DEEPSEEK_API_KEY
ARG GEMINI_API_KEY
ENV OPENAI_API_KEY=$OPENAI_API_KEY
ENV DEEPSEEK_API_KEY=$DEEPSEEK_API_KEY
ENV GEMINI_API_KEY=$GEMINI_API_KEY

RUN apt-get update && apt-get install -y build-essential

RUN apt-get update && apt-get install -y bundler

RUN gem install rails

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle install


COPY . ./


#RUN bundle exec rails db:setup

# Установка часового пояса внутри контейнера
RUN ln -sf /usr/share/zoneinfo/Europe/Kiev /etc/localtime

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]

# Запуск
# =====================sudo docker build -t my-rails-app . ======- это не работает с модулями OpenAI/DeepSeek
#
# Вариант 1: Только OpenAI (без DeepSeek)
# sudo docker build --build-arg OPENAI_API_KEY=your_openai_api_key -t my-rails-app .
#
# Вариант 2: С DeepSeek и Gemini (рекомендуется)
# sudo docker build --build-arg OPENAI_API_KEY=your_openai_api_key --build-arg DEEPSEEK_API_KEY=your_deepseek_api_key --build-arg GEMINI_API_KEY=your_gemini_api_key -t my-rails-app .
#
# где your_openai_api_key, your_deepseek_api_key, your_gemini_api_key - реальные ключи
#
# sudo docker run --rm -p 3000:3000 my-rails-app
#
# ВАЖНО: Gemini используется по умолчанию (основной провайдер).
# Fallback: Gemini -> DeepSeek -> OpenAI.