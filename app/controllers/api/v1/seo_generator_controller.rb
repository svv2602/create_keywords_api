# app/controllers/api/v1/seo_generator_controller.rb

class Api::V1::SeoGeneratorController < ApplicationController
    include StringProcessing
    include StringErrorsProcessing
    include TextOptimization
  
    def generate_seo_text
      # Валидация входящих параметров
      unless valid_params?
        render json: { error: 'Неверные параметры запроса' }, status: :bad_request
        return
      end
  
      begin
        # Генерация SEO текста
        seo_text = SeoTextGenerator.new(generation_params).generate
        
        if seo_text
          render json: { 
            success: true,
            seo_text: seo_text,
            metadata: {
              brand: generation_params[:brand],
              season: generation_params[:season],
              language: generation_params[:language],
              size: generation_params[:size],
              generated_at: Time.current
            }
          }, status: :ok
        else
          render json: { 
            success: false, 
            error: 'Ошибка генерации текста' 
          }, status: :internal_server_error
        end
      rescue => e
        Rails.logger.error "SEO Text Generation Error: #{e.message}"
        render json: { 
          success: false, 
          error: 'Внутренняя ошибка сервера' 
        }, status: :internal_server_error
      end
    end
  
    private
  
    def generation_params
      params.permit(
        :tire_description,
        :brand,
        :season,
        :language,
        :size,
        :seo_requirements,
        :max_tokens
      )
    end
  
    def valid_params?
      required_params = [:tire_description, :brand, :season, :language, :size, :seo_requirements]
      required_params.all? { |param| params[param].present? }
    end
  end