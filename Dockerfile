FROM ruby:3.3.4
# В параметрах сборки укажите API-ключ
ARG OPENAI_API_KEY
ENV OPENAI_API_KEY=$OPENAI_API_KEY

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
# =====================sudo docker build -t my-rails-app . ======- это не работает с модулем OpenAI
#
# sudo docker build --build-arg OPENAI_API_KEY=your_openai_api_key -t my-rails-app .
# где your_openai_api_key - реальный ключ

# sudo docker run --rm -p 3000:3000 my-rails-app