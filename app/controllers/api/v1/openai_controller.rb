# app/controllers/api/openai_controller.rb

class Api::V1::OpenaiController < ApplicationController
  #   PROMPT1 = "Напиши блок FAQs на странцу ЛЕТНИЕ ШИНЫ 175/65 R14
  # Задай по одному вопросу на каждую из нижеуказанных тем
  # Законодательство о зимних шинахё
  # Законодательство о зимних шинахё
  # Рекомендации по вождению зимой
  # Советы по уходу за зимними шинами
  # Ответы на распространенные мифы о зимних шинах
  # Глоссарий терминов, связанных с зимними шинами
  # Маркировка шин
  # Ответы на вопросы должны быть краткими, но содержательными
  # Блок отформатируй, используй заголовки <h3> для вопроса
  # Текст оберни в HTML - теги, с учетом микроразметки"
  def generate_completion
    # Создает заголовки для каждой группы урлов, переменные - размер, бренд, сезон
    repeat_count = 5 # учитываем, что итог будет - repeat_count*[repeat_count_topics]
    repeat_count_topics = 10
    hash_result = {}
    hash_params = {
      "total" => "шины 195/65R15",
      "letnie" => "летние шины 195/65R15",
      "zimnie" => "зимние шины 195/65R15",
      "vsesezonie" => "всесезонные шины 195/65R15",
      "total_brand" => "шины Michelin 195/65R15",
      "letnie_brand" => "летние шины Michelin 195/65R15",
      "zimnie_brand" => "зимние шины Michelin 195/65R15",
      "vsesezonie_brand" => "всесезонные шины Michelin 195/65R15",
    }

    file_path = Rails.root.join('lib', 'template_texts', 'title_h2.json')
    unless File.exist?(file_path)
      File.write(file_path, '{}')
    end
    file_data = File.read(file_path)
    hash_result = JSON.parse(file_data)

    repeat_count.times do

      hash_params.each do |key, value|
        topics = ''
        topics += "\n Сделай #{repeat_count_topics} вариантов короткого качественного, оптимизированного под продажу, заголовка для сео-статьи на странице '#{value}' шинного интернет-магазина ProKoleso."
        topics += "\n Вместо слова 'шины' можно применять его синонимы."
        topics += "\n каждый заголовок оберни в квадратные скобки"
        topics += "\n "

        new_text = ContentWriter.new.write_seo_text(topics, 3500) #['choices'][0]['message']['content'].strip
        if new_text
          begin
            new_text = new_text['choices'][0]['message']['content'].strip
          rescue => e
            puts "Произошла ошибка: #{e.message}"
          end
        end

        # Создание массива для ключа , если он не существует
        hash_result[key] ||= []

        new_text = new_text.scan(/\[(.*?)\]/).flatten
        # Добавление новых уникальных элементов в массив
        hash_result[key] = hash_result[key] | new_text

      end

    end

    File.open(file_path, 'w') do |f|
      f.write(JSON.pretty_generate(hash_result))
    end

    result = hash_result[:total]
    render json: { message: "Все обработано!!!" }, status: :ok

  end






  def generate_completion_old
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

    result = ContentWriter.new.write_draft_post(format_query(result), 2000)

    # puts "prompt =========  #{prompt}"
    render json: { result: result }
    puts result
  end

  def query_сity(topic, сity)
    prompt = "напиши для интернет магазина prokoleso.ua сео текст раздела '#{topic}' для страницы 'Купить шины | #{сity}' "
    prompt += "Текст должен содержать заголовок, а также быть содержательным и интересным для пользователя. "
    prompt += "Текст должен быть оптимизирован под поисковые запросы 'шины #{сity} ', 'резина', 'купить шины в #{сity}'. "

  end

  def format_query(prompt)
    message = ''
    message += "Есть текст: ' #{prompt} '"
    message += "Текст отформатируй и оберни в html - теги. "
    message += "В тексте должен быть только первый заголовок с тегом <h1>, остальные маркировать <h2> или <h3> "
    message += "В ответ вывести только содержание раздела <body> (теги <body>  и </body>  - не выводить ) "
  end

  def write1
    # Assume these are the parameters coming from the API call.
    params = {
      topic: 'description', # This could be job description or any other that API would allow.
      subject: 'шины 195/65 R15', # What is the subject of the description for above topic.
      tone: 'expert', # What is the tone of the description should be. (eg: expert, daring, playful,persuasive, sophisticated)
      keywords: ['шины', 'резина', 'купить в Киеве', 'цена'], # Array of words which must contain in the description
      volume: 1, # For short description volume should be 0, for longer description volume should be 1. (defaults to 0)
    }

    # Now we can build the query using the above params
    query = ["Напиши #{params[:topic]} о #{params[:subject]}."]
    query << "И ответ должен содержать ключевые слова #{params[:keywords].join(',')} ." if params[:keywords].present?
    query << "Стиль #{params[:topic]} должен быть #{params[:tone]}."
    query << "Текст должен быть на русском языке."

    query << if params[:volume].zero? # short
               "#{params[:topic].capitalize} должно быть написано в пределах 30-50 слов."
             else
               # long
               "#{params[:topic].capitalize} должно быть написано в пределах 50-70 слов."
             end

    # response = @client.chat(
    #   parameters: {
    #     model: 'gpt-3.5-turbo', # Required.
    #     messages: [{ role: 'user', content: query.join(' ') }], # Required.
    #     temperature: 0.7
    #   }
    # )

    render json: { result: ContentWriter.new.write_draft_post(query, 2500) }

    # OpenAI response to above build query
    puts response['choices']
    # => {"id"=>"chatcmpl-7gBMbzQcx1amUkNGnU6eveF6C2R0d", ...

    puts response.dig("choices", 0, "message", "content")
    # => Introducing the Fluffiest Teddy Bear Ever! Our delightful teddy bear is the epitome of cuddliness, guaranteed...

    # The API would response with success status is response is valid,
    # Otherwise it will response with error status saying a that error occured.
  end

end