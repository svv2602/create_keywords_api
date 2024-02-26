# app/controllers/api/openai_controller.rb
# require_dependency 'create_keywords_api/open_ai_service'

class Api::V1::OpenaiController < ApplicationController
  PROMPT = "Напиши блок FAQs на странцу ЛЕТНИЕ ШИНЫ 175/65 R14
Задай по одному вопросу на каждую из нижеуказанных тем
Законодательство о зимних шинахё
Законодательство о зимних шинахё
Рекомендации по вождению зимой
Советы по уходу за зимними шинами
Ответы на распространенные мифы о зимних шинах
Глоссарий терминов, связанных с зимними шинами
Маркировка шин
Ответы на вопросы должны быть краткими, но содержательными
Блок отформатируй, используй заголовки <h3> для вопроса
Текст оберни в HTML - теги, с учетом микроразметки"

  def generate_completion
    prompt = PROMPT

    render json: { result: ContentWriter.new.write_draft_post(prompt) }
  end
end