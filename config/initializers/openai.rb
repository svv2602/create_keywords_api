OpenAI.configure do |config|
  config.access_token = ENV.fetch("OPENAI_API_KEY")
  # config.organization_id = ENV.fetch("OPENAI_ORGANIZATION_ID") # Optional.
end

client = OpenAI::Client.new