# app/services/content_writer.rb

class ContentWriter
  # Конфигурация моделей: DeepSeek как основная модель (дешевле, без thinking-overhead),
  # Gemini как fallback для сложных задач
  MODELS = {
    review_generation: 'deepseek-chat',
    complex_analysis: 'gemini-2.5-flash',
    premium_content: 'gemini-2.5-flash',
    seo_generation: 'deepseek-chat',
    fallback: 'gpt-4o-mini'
  }.freeze

  # DeepSeek модели (первый fallback при недоступности Gemini)
  DEEPSEEK_FALLBACK_MODELS = {
    review_generation: 'deepseek-chat',
    complex_analysis: 'deepseek-chat',
    premium_content: 'deepseek-chat',
    seo_generation: 'deepseek-chat'
  }.freeze

  # OpenAI модели (второй fallback при недоступности Gemini и DeepSeek)
  OPENAI_FALLBACK_MODELS = {
    review_generation: 'gpt-4o-mini',
    complex_analysis: 'gpt-4o',
    premium_content: 'gpt-4o',
    seo_generation: 'gpt-4o'
  }.freeze
  
  # Обратная совместимость
  MODEL = MODELS[:review_generation]
  MAX_ATTEMPTS = 5

  def initialize(force_model: nil, skip_rate_limit: false)
    @openai_client = OPENAI_CLIENT
    @deepseek_client = DEEPSEEK_CLIENT
    @gemini_client = GEMINI_CLIENT
    @cost_tracker = AiCostTracker.new
    @rate_limiter = AiRateLimiter.new
    @force_model = force_model  # Принудительный выбор модели через параметр
    @skip_rate_limit = skip_rate_limit  # Пропустить rate limiting (для внутренних вызовов)
  end
  
  # Получить правильный клиент для модели
  def get_client_for_model(model)
    if model.start_with?('gemini') && @gemini_client
      @gemini_client
    elsif model.start_with?('deepseek') && @deepseek_client
      @deepseek_client
    else
      @openai_client
    end
  end

  def write_draft_post(prompt, max_tokens)
    model = select_model(:review_generation)
    client = get_client_for_model(model)

    params = {
      model: model,
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
      max_tokens: adjust_max_tokens_for_model(max_tokens, model),
      top_p: 0.9
    }
    add_penalty_params!(params, frequency_penalty: 0.5, presence_penalty: 0.5, model: model)

    client.chat(parameters: params)
  end

  # +++++++++++++++++++++++++++++++++++++++++
  def rewrite_question(prompt, max_tokens)
    model = select_model(:review_generation)
    client = get_client_for_model(model)

    params = {
      model: model,
      messages: [
        { role: "user", content: prompt }
      ],
      temperature: 0.8,
      max_tokens: adjust_max_tokens_for_model(max_tokens, model),
      top_p: 0.9
    }
    add_penalty_params!(params, frequency_penalty: 0.4, presence_penalty: 0.3, model: model)

    client.chat(parameters: params)
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

    Rails.logger.info "[ContentWriter] Starting generate_review with model: #{model}"

    begin
      # Выполняем запрос с rate limiting
      Rails.logger.info "[ContentWriter] Attempt #{attempts + 1} - calling API..."
      execute_with_rate_limit(model) do
        params = {
          model: model,
          messages: build_review_messages(prompt),
          temperature: 0.7,
          max_tokens: adjust_max_tokens_for_model(max_tokens, model),
          top_p: 0.9
        }
        add_penalty_params!(params, frequency_penalty: 0.3, presence_penalty: 0.4, model: model)

        response = client.chat(parameters: params)

        # Отслеживаем затраты
        @cost_tracker.track_request(model, prompt.length, max_tokens) if @cost_tracker

        response
      end

    rescue OpenAI::Error => e
      attempts += 1

      if attempts < 5
        wait_time = 5 * attempts  # 5, 10, 15, 20 секунд
        Rails.logger.warn "[ContentWriter] API Error: #{e.message}. Attempt #{attempts}/5, retry after #{wait_time}s..."
        sleep(wait_time)
        retry
      else
        Rails.logger.error "[ContentWriter] API Error после 5 попыток: #{e.message}"
        nil
      end

    rescue Faraday::ConnectionFailed, Faraday::TimeoutError, EOFError, Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNRESET, Errno::ETIMEDOUT => e
      # Сетевые ошибки - повторяем с задержкой (5 попыток)
      attempts += 1
      Rails.logger.warn "[ContentWriter] CAUGHT network error: #{e.class} - #{e.message}"

      if attempts < 5
        wait_time = 5 * attempts  # 5, 10, 15, 20 секунд
        Rails.logger.warn "[ContentWriter] Network error: #{e.class} - #{e.message}. Retry #{attempts}/5 after #{wait_time}s..."
        sleep(wait_time)
        retry
      else
        Rails.logger.error "[ContentWriter] Network error после 5 попыток: #{e.class} - #{e.message}"
        nil
      end

    rescue AiRateLimiter::RateLimitExceeded => e
      attempts += 1
      Rails.logger.warn "[ContentWriter] Rate limit exceeded: #{e.message}, retry after #{e.retry_after}s"
      sleep(e.retry_after)
      retry if attempts < 5
      nil
    end
  end




  def write_seo_text_ua(prompt, max_tokens)
    model = select_model(:seo_generation)
    client = get_client_for_model(model)
    attempts = 0

    begin
      params = {
        model: model,
        messages: [
          { role: "system",
            content: 'Вы копирайтер мирового уровня с отличным знанием украинского языка.'
          },
          { role: "user", content: prompt }
        ],
        temperature: 0.7,
        max_tokens: adjust_max_tokens_for_model(max_tokens, model),
        top_p: 0.9
      }
      add_penalty_params!(params, frequency_penalty: 0.4, presence_penalty: 0.3, model: model)

      client.chat(parameters: params)
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
      params = {
        model: model,
        messages: [
          { role: "system",
            content: 'You are a world-class copywriter with excellent knowledge of Russian and Ukrainian.'
          },
          { role: "user", content: prompt }
        ],
        temperature: 0.8,
        top_p: 0.9
      }
      add_penalty_params!(params, presence_penalty: 0.3, model: model)

      client.chat(parameters: params)
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
    # 1. Если явно указана модель через параметр - используем её
    if @force_model.present?
      Rails.logger.info "Using forced model: #{@force_model}"
      return @force_model
    end

    # 2. Проверяем лимиты затрат - переключаемся на fallback
    if @cost_tracker&.daily_cost_exceeded?
      Rails.logger.warn "Daily cost limit exceeded, using fallback model"
      return MODELS[:fallback]
    end

    # 3. Получаем базовую модель (Gemini по умолчанию)
    base_model = MODELS[model_type] || MODELS[:review_generation]

    # 4. Если Gemini недоступен — fallback на DeepSeek
    if base_model.start_with?('gemini') && !@gemini_client
      Rails.logger.warn "Gemini client not available, falling back to DeepSeek"

      if @deepseek_client
        fallback_model = DEEPSEEK_FALLBACK_MODELS[model_type] || 'deepseek-chat'
        Rails.logger.info "Using DeepSeek fallback: #{fallback_model}"
        return fallback_model
      else
        # DeepSeek тоже недоступен — fallback на OpenAI
        Rails.logger.warn "DeepSeek client also not available, falling back to OpenAI"
        fallback_model = OPENAI_FALLBACK_MODELS[model_type] || 'gpt-4o-mini'
        Rails.logger.info "Using OpenAI fallback: #{fallback_model}"
        return fallback_model
      end
    end

    # 5. Если DeepSeek модель (forced или fallback), но клиент недоступен
    if base_model.start_with?('deepseek') && !@deepseek_client
      Rails.logger.warn "DeepSeek client not available, falling back to OpenAI"
      fallback_model = OPENAI_FALLBACK_MODELS[model_type] || 'gpt-4o-mini'
      Rails.logger.info "Using OpenAI fallback: #{fallback_model}"
      return fallback_model
    end

    Rails.logger.info "Using model: #{base_model}"
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

  # Добавить penalty-параметры к запросу (Gemini их не поддерживает в beta)
  def add_penalty_params!(params, frequency_penalty: nil, presence_penalty: nil, model: nil)
    return if model&.start_with?('gemini')

    params[:frequency_penalty] = frequency_penalty if frequency_penalty
    params[:presence_penalty] = presence_penalty if presence_penalty
  end

  # Gemini 2.5 — thinking-модель: часть бюджета max_tokens уходит на внутренние рассуждения.
  # Увеличиваем лимит, чтобы на реальный ответ осталось достаточно токенов.
  def adjust_max_tokens_for_model(max_tokens, model)
    if model&.start_with?('gemini-2.5')
      adjusted = [max_tokens * 8, 65_536].min
      Rails.logger.info "[ContentWriter] Adjusted max_tokens for thinking model #{model}: #{max_tokens} -> #{adjusted}"
      adjusted
    else
      max_tokens
    end
  end

  # Выполнить блок с rate limiting (или без него если skip_rate_limit)
  def execute_with_rate_limit(model, &block)
    if @skip_rate_limit
      yield
    else
      @rate_limiter.with_limit(model, max_wait: 60, &block)
    end
  end

end