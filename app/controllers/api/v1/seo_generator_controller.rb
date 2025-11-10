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
        # Логируем входящие параметры для отладки
        Rails.logger.info "SEO Generator Request - Params: #{generation_params.inspect}"
        
        # Генерация SEO текста
        seo_text = SeoTextGenerator.new(generation_params).generate
        
        # Логируем результат генерации
        Rails.logger.info "SEO Generator Response - Generated text length: #{seo_text&.length || 0} characters"
        Rails.logger.info "SEO Generator Response - Text preview: #{seo_text&.truncate(200) || 'nil'}"
        
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
            error: 'Generated text is incomplete or validation failed. Please try again or reduce text length requirements.'
          }, status: :unprocessable_entity
        end
      rescue => e
        Rails.logger.error "SEO Text Generation Error: #{e.message}"
        Rails.logger.error "SEO Text Generation Backtrace: #{e.backtrace.first(5).join('\n')}"
        render json: { 
          success: false, 
          error: 'Внутренняя ошибка сервера' 
        }, status: :internal_server_error
      end
    end
  
    private
  
  def generation_params
    # Разрешаем все необходимые параметры включая links и format
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
      :force_model,  # Опциональный параметр для прямого указания AI модели
      :format,       # Разрешаем параметр format
      links: [:brand, :model, :brand_size, :brand_sezon, :size],  # Разрешаем массив links
      seo_generator: [  # Разрешаем вложенный хеш seo_generator
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
        :force_model,
        { links: [:brand, :model, :brand_size, :brand_sezon, :size] }
      ]
    )
    
    # Обрабатываем вложенную структуру seo_generator если она есть
    if params[:seo_generator].present?
      seo_generator_params = params[:seo_generator].permit(
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
        :force_model,
        links: [:brand, :model, :brand_size, :brand_sezon, :size]
      )
      permitted.merge!(seo_generator_params)
    end
    
    permitted
  end
  
    def valid_params?
      required_params = [:tire_description, :brand, :model, :season, :language, :size, :product_id]
      required_params.all? { |param| params[param].present? }
    end
  end