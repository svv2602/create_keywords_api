# app/controllers/api/openai_controller.rb

class Api::V1::TyreQuestionsController < ApplicationController

  def generate_questions
    # Определите массив тем.
    сity = "Белая Церковь"
    topics1 = [
      "Летние, Зимние и Всесезонные шины для легковых автомобилей",
      "Шины для разных типов езды (спортивная, комфортная, экономичная)",
      "Большой ассортимент шин разных типоразмеров",
      "Подбор шин по автомобилю в интернет-магазине prokoleso.ua",
      "Новые модели шин всегда в наличии на складе"
    ]
    topics2 = [
      "Советы по выбору и эксплуатации шин",
      "Как выбрать шины для своего автомобиля",
      "Как правильно хранить шины",
      "Как безопасно ездить на шинах",
      "Как подбирать шины для разных сезонов",
      "Особенности эксплуатации шин в городских условиях (Климат, Состояние дорог, Популярные маршруты)",
      "Какие шины лучше всего подходят для данного климата и дорожных условий",
      "Какие шины пользуются наибольшей популярностью у городских жителей"
    ]
    topics3 = [
      "Почему покупатели выбирают prokoleso.ua",
      "Самая удобная покупка - купи шины в prokoleso.ua",
      "prokoleso.ua - покупай только качественные шины"
    ]
    # Используйте метод 'sample' для выбора случайной темы.

    result1 = ContentWriter.new.write_draft_post(query_сity(topics1.sample, сity), 500)
    result2 = ContentWriter.new.write_draft_post(query_сity(topics2.sample, сity), 500)
    result3 = ContentWriter.new.write_draft_post(query_сity(topics3.sample, сity), 500)

    result = result1['choices'][0]['message']['content'].strip +
      result2['choices'][0]['message']['content'].strip +
      result3['choices'][0]['message']['content'].strip

    result =  ContentWriter.new.write_draft_post(format_query(result), 2000)

    # puts "prompt =========  #{prompt}"
    render json: { result: result }
    puts result
  end

  def questions
    array_questions('TyresFaq', 3)
  end

  def array_questions(table, count)
    questions = []
    table_copy = table + 'Copy' # Преобразуем имя таблицы-копии
    puts table
    puts table_copy

    count.times do
      @service.copy_table_to_table_copy_if_empty(table, table_copy)
      questions << @service.find_and_destroy_random_record(table_copy)
    end
    puts questions
  end


end