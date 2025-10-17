# app/services/ai_cost_tracker.rb

class AiCostTracker
  # Цены за 1M токенов (в USD)
  MODEL_PRICING = {
    # OpenAI модели
    'gpt-4o' => { input: 2.50, output: 10.0 },
    'gpt-4o-mini' => { input: 0.15, output: 0.6 },
    'gpt-4-turbo' => { input: 10.0, output: 30.0 },
    'gpt-3.5-turbo' => { input: 0.5, output: 1.5 },
    
    # DeepSeek модели (стандартные часы UTC 00:30–16:30)
    'deepseek-chat' => { input: 0.27, output: 1.10 },
    'deepseek-reasoner' => { input: 0.55, output: 2.19 },
    
    # DeepSeek модели (льготные часы UTC 16:30–00:30) - в 2 раза дешевле
    'deepseek-chat-discount' => { input: 0.135, output: 0.55 },
    'deepseek-reasoner-discount' => { input: 0.275, output: 1.10 }
  }.freeze
  
  DAILY_COST_LIMIT = Rails.env.production? ? 200.0 : 50.0  # USD
  
  def initialize
    @today = Date.current.to_s
  end
  
  # Проверка, льготное ли время для DeepSeek (UTC 16:30-00:30)
  def self.deepseek_discount_time?
    current = Time.now.utc
    hour = current.hour
    minute = current.min
    
    # Льготные часы: 16:30-00:30 UTC
    (hour > 16 || hour < 0) || (hour == 16 && minute >= 30) || (hour == 0 && minute < 30)
  end
  
  # Преобразование имени модели для учета льготного времени
  def self.effective_model_name(model)
    if model.start_with?('deepseek') && !model.include?('discount') && deepseek_discount_time?
      "#{model}-discount"
    else
      model
    end
  end
  
  def track_request(model, input_tokens, output_tokens)
    # Учитываем льготное время для DeepSeek
    effective_model = self.class.effective_model_name(model)
    cost = calculate_cost(effective_model, input_tokens, output_tokens)
    
    # Увеличиваем дневной счетчик
    Rails.cache.increment(daily_cost_key, cost, expires_in: 24.hours)
    
    # Сохраняем статистику (используем оригинальное имя модели)
    save_request_stats(model, input_tokens, output_tokens, cost, effective_model)
    
    # Проверяем лимиты
    check_daily_limits
    
    cost
  end
  
  def daily_cost_exceeded?
    current_daily_cost >= DAILY_COST_LIMIT
  end
  
  def current_daily_cost
    Rails.cache.read(daily_cost_key) || 0.0
  end
  
  def remaining_daily_budget
    [DAILY_COST_LIMIT - current_daily_cost, 0.0].max
  end
  
  def daily_stats
    {
      total_cost: current_daily_cost,
      remaining_budget: remaining_daily_budget,
      limit_exceeded: daily_cost_exceeded?,
      requests_count: Rails.cache.read(daily_requests_key) || 0,
      average_cost_per_request: calculate_average_cost_per_request
    }
  end
  
  def weekly_stats
    # Собираем статистику за неделю
    week_costs = []
    7.times do |i|
      date = (Date.current - i.days).to_s
      cost = Rails.cache.read("ai_cost_#{date}") || 0.0
      week_costs << { date: date, cost: cost }
    end
    
    {
      daily_costs: week_costs.reverse,
      total_week_cost: week_costs.sum { |day| day[:cost] },
      average_daily_cost: week_costs.sum { |day| day[:cost] } / 7.0
    }
  end
  
  def model_usage_stats
    stats = {}
    
    MODEL_PRICING.each_key do |model|
      model_key = "ai_model_usage_#{@today}_#{model}"
      usage = Rails.cache.read(model_key) || { requests: 0, cost: 0.0 }
      stats[model] = usage
    end
    
    stats
  end
  
  private
  
  def calculate_cost(model, input_tokens, output_tokens)
    pricing = MODEL_PRICING[model]
    return 0.0 unless pricing
    
    # Конвертируем символы в токены (приблизительно)
    input_token_count = estimate_tokens(input_tokens)
    output_token_count = estimate_tokens(output_tokens)
    
    input_cost = (input_token_count / 1_000_000.0) * pricing[:input]
    output_cost = (output_token_count / 1_000_000.0) * pricing[:output]
    
    input_cost + output_cost
  end
  
  def estimate_tokens(text_or_count)
    case text_or_count
    when String
      # Приблизительно 4 символа = 1 токен для русского текста
      text_or_count.length / 4.0
    when Numeric
      text_or_count.to_f
    else
      0.0
    end
  end
  
  def save_request_stats(model, input_tokens, output_tokens, cost, effective_model = nil)
    # Увеличиваем счетчик запросов
    Rails.cache.increment(daily_requests_key, 1, expires_in: 24.hours)
    
    # Сохраняем статистику по модели (с указанием эффективной модели для цены)
    stats_model = effective_model || model
    model_key = "ai_model_usage_#{@today}_#{stats_model}"
    current_stats = Rails.cache.read(model_key) || { requests: 0, cost: 0.0 }
    
    new_stats = {
      requests: current_stats[:requests] + 1,
      cost: current_stats[:cost] + cost
    }
    
    Rails.cache.write(model_key, new_stats, expires_in: 7.days)
  end
  
  def check_daily_limits
    if daily_cost_exceeded?
      Rails.logger.warn "Daily AI cost limit exceeded: $#{current_daily_cost.round(2)}"
      
      # Автоматически снижаем использование AI
      if current_daily_cost > DAILY_COST_LIMIT * 1.2
        FeatureFlags.emergency_disable_ai!
      end
    end
  end
  
  def calculate_average_cost_per_request
    requests_count = Rails.cache.read(daily_requests_key) || 0
    return 0.0 if requests_count == 0
    
    current_daily_cost / requests_count
  end
  
  def daily_cost_key
    "ai_cost_#{@today}"
  end
  
  def daily_requests_key
    "ai_requests_#{@today}"
  end
end

