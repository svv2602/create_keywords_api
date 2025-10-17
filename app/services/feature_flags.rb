# app/services/feature_flags.rb

class FeatureFlags
  # Ключи для кеширования настроек
  CACHE_KEYS = {
    ai_processing_percentage: 'ai_processing_percentage',
    post_processing_percentage: 'post_processing_percentage',
    smart_emoji_enabled: 'smart_emoji_enabled',
    length_control_enabled: 'length_control_enabled',
    hybrid_processing_enabled: 'hybrid_processing_enabled',
    force_ai_processing: 'force_ai_processing',
    universal_postprocessing_enabled: 'universal_postprocessing_enabled',
    use_deepseek_for_seo: 'use_deepseek_for_seo',
    use_deepseek_for_reviews: 'use_deepseek_for_reviews'
  }.freeze
  
  # Значения по умолчанию
  DEFAULTS = {
    ai_processing_percentage: 30,      # 30% отзывов через AI
    post_processing_percentage: 100,    # 70% AI отзывов с постобработкой
    smart_emoji_enabled: true,         # умные эмодзи включены
    length_control_enabled: true,      # контроль длины включен
    hybrid_processing_enabled: true,   # гибридная обработка включена
    force_ai_processing: false,        # принудительная AI обработка выключена
    universal_postprocessing_enabled: true,  # универсальная постобработка для уникальности
    use_deepseek_for_seo: true,        # использовать DeepSeek для SEO-текстов (экономия 90%)
    use_deepseek_for_reviews: false    # использовать DeepSeek для отзывов в льготные часы
  }.freeze
  
  class << self
    def use_new_ai_model?(user_id = nil)
      percentage = get_setting(:ai_processing_percentage)
      
      if user_id
        # Консистентное распределение по user_id
        (user_id.to_s.hash.abs % 100) < percentage
      else
        rand(100) < percentage
      end
    end
    
    def use_post_processing?(user_id = nil)
      return false unless use_new_ai_model?(user_id)
      
      percentage = get_setting(:post_processing_percentage)
      
      if user_id
        (user_id.to_s.hash.abs % 100) < percentage
      else
        rand(100) < percentage
      end
    end
    
    def smart_emoji_enabled?
      get_setting(:smart_emoji_enabled)
    end
    
    def length_control_enabled?
      get_setting(:length_control_enabled)
    end
    
    def hybrid_processing_enabled?
      get_setting(:hybrid_processing_enabled)
    end
    
    # Проверка включения универсальной постобработки
    def universal_postprocessing_enabled?
      get_setting(:universal_postprocessing_enabled)
    end
    
    def force_ai_processing?
      get_setting(:force_ai_processing)
    end
    
    # DeepSeek настройки
    def use_deepseek_for_seo?
      # Проверяем наличие API ключа
      return false unless ENV['DEEPSEEK_API_KEY'].present?
      get_setting(:use_deepseek_for_seo)
    end
    
    def use_deepseek_for_reviews?
      # Проверяем наличие API ключа
      return false unless ENV['DEEPSEEK_API_KEY'].present?
      get_setting(:use_deepseek_for_reviews)
    end
    
    # Методы для управления настройками
    def set_ai_processing_percentage(percentage)
      set_setting(:ai_processing_percentage, percentage.to_i.clamp(0, 100))
    end
    
    def set_post_processing_percentage(percentage)
      set_setting(:post_processing_percentage, percentage.to_i.clamp(0, 100))
    end
    
    def enable_smart_emoji!
      set_setting(:smart_emoji_enabled, true)
    end
    
    def disable_smart_emoji!
      set_setting(:smart_emoji_enabled, false)
    end
    
    def enable_length_control!
      set_setting(:length_control_enabled, true)
    end
    
    def disable_length_control!
      set_setting(:length_control_enabled, false)
    end
    
    def enable_hybrid_processing!
      set_setting(:hybrid_processing_enabled, true)
    end
    
    def disable_hybrid_processing!
      set_setting(:hybrid_processing_enabled, false)
    end
    
    def enable_force_ai_processing!
      set_setting(:force_ai_processing, true)
    end
    
    def disable_force_ai_processing!
      set_setting(:force_ai_processing, false)
    end
    
    # DeepSeek управление
    def enable_deepseek_for_seo!
      set_setting(:use_deepseek_for_seo, true)
    end
    
    def disable_deepseek_for_seo!
      set_setting(:use_deepseek_for_seo, false)
    end
    
    def enable_deepseek_for_reviews!
      set_setting(:use_deepseek_for_reviews, true)
    end
    
    def disable_deepseek_for_reviews!
      set_setting(:use_deepseek_for_reviews, false)
    end
    
    # Получение всех настроек
    def current_settings
      settings = {}
      DEFAULTS.each_key do |key|
        settings[key] = get_setting(key)
      end
      settings
    end
    
    # Сброс всех настроек к значениям по умолчанию
    def reset_to_defaults!
      CACHE_KEYS.each_key do |key|
        Rails.cache.delete(CACHE_KEYS[key])
      end
    end
    
    # Постепенное увеличение процента AI обработки
    def gradually_increase_ai_percentage!(step: 5, max: 50)
      current = get_setting(:ai_processing_percentage)
      new_percentage = [current + step, max].min
      set_ai_processing_percentage(new_percentage)
      
      Rails.logger.info "AI processing percentage increased to #{new_percentage}%"
      new_percentage
    end
    
    # Быстрое отключение AI при проблемах
    def emergency_disable_ai!
      set_ai_processing_percentage(0)
      disable_force_ai_processing!
      
      Rails.logger.warn "AI processing emergency disabled!"
    end
    
    def set_setting(key, value)
      cache_key = CACHE_KEYS[key]
      Rails.cache.write(cache_key, value, expires_in: 24.hours)
      
      Rails.logger.info "FeatureFlag #{key} set to #{value}"
      value
    end
    
    def get_setting(key)
      cache_key = CACHE_KEYS[key]
      default_value = DEFAULTS[key]
      
      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        # Можно добавить загрузку из БД или конфигурационного файла
        default_value
      end
    end
    
    private
  end
end

