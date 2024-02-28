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
    # Определите массив тем.
    topics = ["Туризм во Франции", "Преимущества электрокаров", "Биологическое разнообразие Амазонки", "Будущее космической технологии", "Похудение через йогу"]

    # Используйте метод 'sample' для выбора случайной темы.
    prompt = topics.sample

    result = ContentWriter.new.write_draft_post(prompt, 2500)

    render json: { result: result['choices'][0]['message']['content'].strip }
    puts result['choices'][0]['message']['content'].strip
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
             else # long
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