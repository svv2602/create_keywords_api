# app/services/content_writer.rb

class ContentWriter
  # Конфигурация моделей
  MODELS = {
    review_generation: 'gpt-4o-mini',    # для массовой генерации отзывов
    complex_analysis: 'deepseek-chat',   # DeepSeek для сложных задач (в 10-20х дешевле!)
    premium_content: 'deepseek-chat',    # DeepSeek для премиум контента (экономия 90%)
    seo_generation: 'deepseek-chat',     # DeepSeek для SEO-текстов
    fallback: 'gpt-3.5-turbo'           # запасная модель при ошибках
  }.freeze
  
  # Опциональные DeepSeek модели для льготных часов
  DEEPSEEK_MODELS = {
    review_generation: 'deepseek-chat',  # можно использовать в льготные часы
    complex_analysis: 'deepseek-chat',
    premium_content: 'deepseek-chat',
    seo_generation: 'deepseek-chat'
  }.freeze
  
  # Обратная совместимость
  MODEL = MODELS[:review_generation]
  MAX_ATTEMPTS = 5

  def initialize
    @openai_client = OPENAI_CLIENT
    @deepseek_client = DEEPSEEK_CLIENT
    @cost_tracker = AiCostTracker.new
  end
  
  # Получить правильный клиент для модели
  def get_client_for_model(model)
    if model.start_with?('deepseek') && @deepseek_client
      @deepseek_client
    else
      @openai_client
    end
  end

  def write_draft_post(prompt, max_tokens)
    model = select_model(:review_generation)
    client = get_client_for_model(model)
    
    # prompt = "Write a #{max_tokens} word blogpost about '#{title}'."
    client.chat(
      parameters: {
        model: MODEL,
        messages: [
          { role: "system",
            content: 'Вы копирайтер мирового уровня. Пожалуйста, создайте SEO-текст с заголовками.'
          },

          { role: "system",
            content: "Текст должен быть на русском языке"
          },
          { role: "user", content: prompt }
        ],
        temperature: 0.8,
        # Temperature (температура): Можно установить значение около 0.5-0.7, чтобы получить
        # более консервативные и ожидаемые ответы. Это поможет избежать слишком экспрессивных
        # или неожиданных фраз.
        max_tokens: max_tokens,
        top_p: 0.9,
        #Top p: Рекомендуется использовать значение около 0.9, чтобы модель могла выбирать
        # наиболее вероятные следующие слова, исходя из распределения вероятностей,
        # что способствует генерации более качественного текста.
        frequency_penalty: 0.5,
        # Frequency Penalty (штраф за частоту): Можно установить значение около 0.2-0.5,
        # чтобы умеренно контролировать повторяемость ключевых слов или фраз в тексте.
        # Это поможет избежать пересыщения текста ключевыми словами и обеспечит его естественность.
        presence_penalty: 0.5
        # Presence Penalty (штраф за присутствие):
        # Также можно установить значение около 0.2-0.5, чтобы стимулировать разнообразие лексики
        # в тексте и избежать излишнего повторения слов или фраз.
      }
    )
  end

  # +++++++++++++++++++++++++++++++++++++++++
  def rewrite_question(prompt, max_tokens)
    model = select_model(:review_generation)
    client = get_client_for_model(model)
    
    # prompt = "Write a #{max_tokens} word blogpost about '#{title}'."
    client.chat(
      parameters: {
        model: MODEL,
        messages: [
          # { role: "system",
          #   content: 'Вы копирайтер мирового уровня.'
          # },
          { role: "user", content: prompt }
        ],
        temperature: 0.8,
        max_tokens: max_tokens,
        top_p: 0.9,
        frequency_penalty: 0.4,
        presence_penalty: 0.3
      }
    )
  end





  # ++++++++++++++++++++++++++++++++++++++++++++

  def write_seo_text(prompt, max_tokens)
    # SEO-тексты используют DeepSeek для экономии
    generate_review(prompt, max_tokens, model_type: :seo_generation)
  end
  
  def generate_review(prompt, max_tokens, model_type: :review_generation)
    model = select_model(model_type)
    client = get_client_for_model(model)
    attempts = 0

    begin
      response = client.chat(
        parameters: {
          model: model,
          messages: build_review_messages(prompt),
          temperature: 0.7,        # снижаем для большей стабильности
          max_tokens: max_tokens,
          top_p: 0.9,
          frequency_penalty: 0.3,  # уменьшаем повторения
          presence_penalty: 0.4    # увеличиваем разнообразие
        }
      )
      
      # Отслеживаем затраты
      @cost_tracker.track_request(model, prompt.length, max_tokens) if @cost_tracker
      
      response
      
    rescue OpenAI::Error => e
      attempts += 1

      if attempts < MAX_ATTEMPTS
        puts "Произошла ошибка: #{e.message}. Повторная попытка..."
        # При ошибке пробуем fallback модель
        model = MODELS[:fallback] if attempts > 2
        retry
      else
        puts "Ошибка после #{MAX_ATTEMPTS} попыток: #{e.message}"
        nil
      end
    end
  end




  def write_seo_text_ua(prompt, max_tokens)
    model = select_model(:seo_generation)
    client = get_client_for_model(model)
    attempts = 0

    begin

      # prompt = "Write a #{max_tokens} word blogpost about '#{title}'."
      client.chat(
        parameters: {
          model: MODEL,
          messages: [
            { role: "system",
              content: 'Вы копирайтер мирового уровня с отличным знанием украинского языка.'
            },
            { role: "user", content: prompt }
          ],
          temperature: 0.7,
          max_tokens: max_tokens,
          top_p: 0.9,
          frequency_penalty: 0.4,
          presence_penalty: 0.3
        }
      )
    rescue OpenAI::Error => e
      attempts += 1

      if attempts < MAX_ATTEMPTS
        puts "Произошла ошибка: #{e.message}. Повторная попытка..."
        retry
      else
        puts "Ошибка после #{MAX_ATTEMPTS} попыток: #{e.message}"
        nil
      end
    end
  end



  def write_seo_city(prompt)
    model = select_model(:seo_generation)
    client = get_client_for_model(model)
    attempts = 0

    begin
      client.chat(
        parameters: {
          model: MODEL,
          messages: [
            { role: "system",
              content: 'You are a world-class copywriter with excellent knowledge of Russian and Ukrainian.'
            },
            { role: "user", content: prompt }
          ],
          temperature: 0.8,
          # max_tokens: max_tokens,
          top_p: 0.9,
          # frequency_penalty: 0.4,
          presence_penalty: 0.3
        }
      )
    rescue OpenAI::Error => e
      attempts += 1

      if attempts < MAX_ATTEMPTS
        puts "Произошла ошибка: #{e.message}. Повторная попытка..."
        retry
      else
        puts "Ошибка после #{MAX_ATTEMPTS} попыток: #{e.message}"
        nil
      end
    end
  end
  
  private
  
  def select_model(model_type)
    # Проверяем лимиты затрат
    if @cost_tracker&.daily_cost_exceeded?
      return MODELS[:fallback]
    end
    
    # Получаем базовую модель
    base_model = MODELS[model_type] || MODELS[:review_generation]
    
    # Если DeepSeek недоступен, используем OpenAI альтернативу
    if base_model.start_with?('deepseek') && !@deepseek_client
      Rails.logger.warn "DeepSeek client not available, falling back to OpenAI"
      
      case model_type
      when :complex_analysis
        return 'gpt-4o'
      when :premium_content
        return 'gpt-4o'
      when :seo_generation
        return 'gpt-4o'
      else
        return 'gpt-4o-mini'
      end
    end
    
    # Проверяем Feature Flags для использования DeepSeek в льготные часы
    if FeatureFlags.use_deepseek_for_reviews? && 
       model_type == :review_generation && 
       AiCostTracker.deepseek_discount_time?
      return 'deepseek-chat'
    end
    
    base_model
  end
  
  def build_review_messages(prompt)
    [
      { 
        role: "system", 
        content: system_prompt_for_reviews 
      },
      { 
        role: "user", 
        content: prompt 
      }
    ]
  end
  
  def system_prompt_for_reviews
    <<~PROMPT
      Ты опытный автомобилист, который пишет честные отзывы о шинах на основе реального опыта.
      
      Требования к отзыву:
      - Пиши от первого лица, как реальный пользователь
      - Используй разговорный стиль, но грамотно
      - Включай конкретные детали об использовании шин
      - Избегай рекламных клише и шаблонных фраз
      - Добавляй личные наблюдения и сравнения
      - Используй естественные речевые обороты
      - Не используй слишком технические термины без объяснения
      
      Стиль: неформальный, но информативный
      Длина: соответствует указанной в запросе
      Язык: русский (если не указано иное)
    PROMPT
  end

end