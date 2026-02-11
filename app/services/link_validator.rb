require 'net/http'
require 'json'

class LinkValidator
  API_URL = "https://prokoleso.com/api/link-check/listings"
  AUTH_HEADER = "Basic YWRtaW46MTIzNDU1NDMyMQ=="
  TIMEOUT = 10 # секунд

  # Принимает массив queries [{text: "...", url: "/shiny/..."}, ...]
  # Возвращает { queries: [...], error: nil } или { queries: [], error: "сообщение" }
  def self.validate(queries)
    return { queries: [], error: nil } if queries.empty?

    # Собираем URL без ведущего /
    urls = queries.map { |q| q[:url].sub(%r{\A/}, '') }

    uri = URI(API_URL)
    body = { urls: urls }.to_json

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request['Authorization'] = AUTH_HEADER
      request.body = body
      http.request(request)
    end

    unless response.code == '200'
      error_msg = "API returned #{response.code}: #{response.body.to_s[0..200]}"
      Rails.logger.error "[LinkValidator] #{error_msg}"
      return { queries: [], error: error_msg }
    end

    data = JSON.parse(response.body)
    results = data['results'] || data

    # Собираем Set валидных URL (без ведущего /)
    # API возвращает поле "input" (не "url")
    valid_urls = Set.new
    results.each do |item|
      if item['status'] == 'ok' && item['has_products'] == true
        valid_urls << item['input']
      end
    end

    valid_count = valid_urls.size
    Rails.logger.info "[LinkValidator] #{urls.size} URLs checked, #{valid_count} valid"

    # Фильтруем исходные queries
    filtered = queries.select { |q| valid_urls.include?(q[:url].sub(%r{\A/}, '')) }

    { queries: filtered, error: nil }
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    error_msg = "API timeout: #{e.message}"
    Rails.logger.error "[LinkValidator] #{error_msg}"
    { queries: [], error: error_msg }
  rescue StandardError => e
    error_msg = "API error: #{e.message}"
    Rails.logger.error "[LinkValidator] #{error_msg}"
    { queries: [], error: error_msg }
  end
end
