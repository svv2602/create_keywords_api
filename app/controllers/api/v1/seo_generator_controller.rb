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
          product_id: generation_params[:product_id],
          metadata: {
            brand: generation_params[:brand],
            model: generation_params[:model],
            season: generation_params[:season],
            language: generation_params[:language],
            size: generation_params[:size],
            load_index: generation_params[:load_index],
            speed_index: generation_params[:speed_index],
            ai_model: generation_params[:force_model] || 'deepseek-chat (default)',
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
      permitted = params.permit(
        :tire_description,
        :brand,
        :model,
        :season,
        :language,
        :size,
        :product_id,
        :load_index,
        :speed_index,
        :seo_requirements,
        :max_tokens,
        :force_model  # Опциональный параметр для прямого указания AI модели
      )
      
      # Обрабатываем links отдельно, чтобы избежать проблем с permit
      if params[:links].present?
        links_array = []
        params[:links].each do |link|
          if link.is_a?(ActionController::Parameters)
            links_array << link.permit(:brand, :model, :brand_size, :brand_sezon, :size).to_h
          elsif link.is_a?(Hash)
            links_array << link.slice('brand', 'model', 'brand_size', 'brand_sezon', 'size')
          end
        end
        permitted[:links] = links_array
      end
      
      permitted
    end
  
    def valid_params?
      required_params = [:tire_description, :brand, :model, :season, :language, :size, :product_id]
      required_params.all? { |param| params[param].present? }
    end
  end