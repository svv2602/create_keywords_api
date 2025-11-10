# app/controllers/api/v1/car_seo_texts_controller.rb
class Api::V1::CarSeoTextsController < ApplicationController

  # GET /api/v1/car_seo_text
  # Параметры:
  #   - brand (обязательно): марка автомобиля, например "toyota"
  #   - model (обязательно): модель автомобиля, например "camry"
  #   - language (обязательно): язык текста "ru" или "ua"
  #   - typical_sizes (обязательно): размеры шин через запятую, например "215/55R17,215/60R16"
  #   - generation (опционально): поколение автомобиля, например "XV70"
  #   - production_years (опционально): годы выпуска, например "2017-2023"
  #   - body_type (опционально): тип кузова, например "седан"
  #   - car_class (опционально): класс автомобиля, например "D"
  #
  # Примеры запросов:
  # curl "http://localhost:3000/api/v1/car_seo_text?brand=toyota&model=camry&language=ru&typical_sizes=215/55R17,215/60R16"
  # curl "http://localhost:3000/api/v1/car_seo_text?brand=toyota&model=camry&language=ua&typical_sizes=215/55R17,215/60R16&body_type=седан&car_class=D"
  def generate
    begin
      # Парсим размеры из строки в массив
      typical_sizes = params[:typical_sizes]&.split(',')&.map(&:strip) || []

      generator_params = {
        brand: params[:brand],
        model: params[:model],
        language: params[:language],
        typical_sizes: typical_sizes,
        generation: params[:generation],
        production_years: params[:production_years],
        body_type: params[:body_type],
        car_class: params[:car_class]
      }

      generator = CarSeoTextGenerator.new(generator_params)
      result = generator.generate

      if result[:error]
        render json: { error: result[:error] }, status: :unprocessable_entity
      else
        render json: result
      end

    rescue ArgumentError => e
      render json: { error: e.message }, status: :bad_request
    rescue => e
      render json: { error: "Internal server error: #{e.message}" }, status: :internal_server_error
    end
  end

end
