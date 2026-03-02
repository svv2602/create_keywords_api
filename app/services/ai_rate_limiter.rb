# app/services/ai_rate_limiter.rb
#
# Rate limiter для AI API запросов (DeepSeek, OpenAI)
# Защищает от превышения лимитов API провайдеров
#
# Лимиты DeepSeek API:
#   - 500 RPM (requests per minute) для deepseek-chat
#   - 60 RPM для deepseek-reasoner
#
# Лимиты OpenAI API (зависят от tier):
#   - Tier 1: 500 RPM для gpt-4.1-mini, 500 RPM для gpt-4o
#   - Tier 2+: выше
#
class AiRateLimiter
  # Лимиты запросов в минуту (консервативные, чтобы оставить запас)
  RATE_LIMITS = {
    'deepseek-chat' => { rpm: 400, concurrent: 50 },      # DeepSeek: 500 RPM, берем 400
    'deepseek-reasoner' => { rpm: 50, concurrent: 10 },   # DeepSeek: 60 RPM, берем 50
    'gpt-4o' => { rpm: 400, concurrent: 50 },             # OpenAI Tier 1+
    'gpt-4.1-mini' => { rpm: 400, concurrent: 50 },        # OpenAI Tier 1+
    'gpt-4-turbo' => { rpm: 400, concurrent: 50 },
    'gpt-3.5-turbo' => { rpm: 400, concurrent: 50 },
    'gemini-2.5-flash' => { rpm: 300, concurrent: 30 }  # Pay-as-you-go: 2000 RPM, берем 300 консервативно
  }.freeze

  DEFAULT_LIMITS = { rpm: 100, concurrent: 20 }.freeze

  class RateLimitExceeded < StandardError
    attr_reader :retry_after

    def initialize(message, retry_after: 1)
      super(message)
      @retry_after = retry_after
    end
  end

  def initialize
    @mutex = Mutex.new
  end

  # Проверить и получить разрешение на запрос
  # Возвращает true если можно выполнить, false если нужно подождать
  def acquire(model)
    limits = RATE_LIMITS[model] || DEFAULT_LIMITS

    @mutex.synchronize do
      # Проверяем лимит запросов в минуту
      return false if rpm_limit_exceeded?(model, limits[:rpm])

      # Проверяем лимит параллельных запросов
      return false if concurrent_limit_exceeded?(model, limits[:concurrent])

      # Регистрируем запрос
      register_request(model)
      increment_concurrent(model)

      true
    end
  end

  # Освободить слот после завершения запроса
  def release(model)
    @mutex.synchronize do
      decrement_concurrent(model)
    end
  end

  # Выполнить блок с rate limiting
  # Автоматически ждет если лимит превышен
  def with_limit(model, max_wait: 30, &block)
    waited = 0
    wait_interval = 0.5

    until acquire(model)
      if waited >= max_wait
        raise RateLimitExceeded.new(
          "Rate limit exceeded for #{model}, waited #{waited}s",
          retry_after: calculate_retry_after(model)
        )
      end

      sleep(wait_interval)
      waited += wait_interval
    end

    begin
      yield
    ensure
      release(model)
    end
  end

  # Текущая статистика
  def stats(model = nil)
    if model
      model_stats(model)
    else
      all_stats
    end
  end

  # Сколько запросов можно сделать прямо сейчас
  def available_capacity(model)
    limits = RATE_LIMITS[model] || DEFAULT_LIMITS

    rpm_available = limits[:rpm] - current_rpm(model)
    concurrent_available = limits[:concurrent] - current_concurrent(model)

    [rpm_available, concurrent_available, 0].max
  end

  # Проверить, можно ли выполнить N запросов
  def can_handle?(model, count)
    available_capacity(model) >= count
  end

  private

  def rpm_limit_exceeded?(model, limit)
    current_rpm(model) >= limit
  end

  def concurrent_limit_exceeded?(model, limit)
    current_concurrent(model) >= limit
  end

  def current_rpm(model)
    key = rpm_key(model)
    Rails.cache.read(key) || 0
  end

  def current_concurrent(model)
    key = concurrent_key(model)
    Rails.cache.read(key) || 0
  end

  def register_request(model)
    key = rpm_key(model)
    # Счетчик запросов за минуту, автоматически сбрасывается через 60 секунд
    if Rails.cache.read(key)
      Rails.cache.increment(key)
    else
      Rails.cache.write(key, 1, expires_in: 60.seconds)
    end
  end

  def increment_concurrent(model)
    key = concurrent_key(model)
    if Rails.cache.read(key)
      Rails.cache.increment(key)
    else
      Rails.cache.write(key, 1, expires_in: 5.minutes)
    end
  end

  def decrement_concurrent(model)
    key = concurrent_key(model)
    current = Rails.cache.read(key) || 0
    if current > 1
      Rails.cache.decrement(key)
    else
      Rails.cache.delete(key)
    end
  end

  def calculate_retry_after(model)
    # Оцениваем, когда освободится слот
    limits = RATE_LIMITS[model] || DEFAULT_LIMITS
    current = current_rpm(model)

    if current >= limits[:rpm]
      # Ждем до сброса минутного счетчика (макс 60 сек)
      60
    else
      # Ждем освобождения concurrent слота (обычно быстро)
      5
    end
  end

  def model_stats(model)
    limits = RATE_LIMITS[model] || DEFAULT_LIMITS
    {
      model: model,
      current_rpm: current_rpm(model),
      rpm_limit: limits[:rpm],
      current_concurrent: current_concurrent(model),
      concurrent_limit: limits[:concurrent],
      available_capacity: available_capacity(model)
    }
  end

  def all_stats
    RATE_LIMITS.keys.map { |model| model_stats(model) }
  end

  def rpm_key(model)
    "ai_rate_rpm_#{model}"
  end

  def concurrent_key(model)
    "ai_rate_concurrent_#{model}"
  end
end
