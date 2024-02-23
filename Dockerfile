FROM ruby:3.2.2

RUN apt-get update && apt-get install -y build-essential

RUN apt-get update && apt-get install -y bundler

RUN gem install rails

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle install


COPY . ./

RUN bundle exec rails db:setup

# Установка часового пояса внутри контейнера
RUN ln -sf /usr/share/zoneinfo/Europe/Kiev /etc/localtime

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]

# Запуск
# sudo docker build -t my-rails-app .
# sudo docker run --rm -p 3000:3000 my-rails-app