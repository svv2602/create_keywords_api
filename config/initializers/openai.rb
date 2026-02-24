# Конфигурация OpenAI API
OpenAI.configure do |config|
  config.access_token = ENV.fetch("OPENAI_API_KEY")
  # config.organization_id = ENV.fetch("OPENAI_ORGANIZATION_ID") # Optional.
end

# Основной OpenAI клиент
OPENAI_CLIENT = OpenAI::Client.new

# DeepSeek API клиент (совместим с OpenAI SDK)
# DeepSeek использует OpenAI-совместимый интерфейс
DEEPSEEK_CLIENT = if ENV['DEEPSEEK_API_KEY'].present?
  OpenAI::Client.new(
    access_token: ENV['DEEPSEEK_API_KEY'],
    uri_base: "https://api.deepseek.com",
    request_timeout: 300  # 5 минут - DeepSeek может быть медленнее при высокой нагрузке
  )
else
  nil
end

# Gemini API клиент (OpenAI-совместимый endpoint)
GEMINI_CLIENT = if ENV['GEMINI_API_KEY'].present?
  OpenAI::Client.new(
    access_token: ENV['GEMINI_API_KEY'],
    uri_base: "https://generativelanguage.googleapis.com/v1beta/openai/",
    request_timeout: 300
  )
else
  nil
end

# Для обратной совместимости
client = OPENAI_CLIENT