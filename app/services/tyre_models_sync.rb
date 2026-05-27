require "net/http"
require "uri"
require "json"

class TyreModelsSync
  API_URL = "https://prokoleso.ua/api/v1/catalog/top-models".freeze

  SEASON_MAP = {
    "Летние шины"      => "letnie",
    "Зимние шины"      => "zimnie",
    "Всесезонные шины" => "vsesezonie"
  }.freeze

  OUTPUT_PATH = Rails.root.join("lib", "tyre_models.json").to_s

  class SyncError < StandardError; end

  @sync_mutex = Mutex.new

  def self.refresh_if_stale!
    return if fresh?

    @sync_mutex.synchronize do
      return if fresh?
      sync!
    end
  rescue SyncError => e
    Rails.logger.error("[TyreModelsSync] #{e.message}; keeping existing JSON")
    nil
  end

  def self.fresh?
    File.exist?(OUTPUT_PATH) && File.mtime(OUTPUT_PATH).to_date == Date.current
  end

  def self.sync!
    models = preview
    raise SyncError, "API returned no valid records" if models.empty?

    write_atomic(models)
    PopularQueriesGenerator.reset_brands_cache! if defined?(PopularQueriesGenerator)
    Rails.logger.info("[TyreModelsSync] synced #{models.size} models")
    models.size
  end

  def self.preview
    token = ENV["PROKOLESO_API_TOKEN"]
    raise SyncError, "PROKOLESO_API_TOKEN is not set" if token.nil? || token.empty?

    response = fetch(token)
    payload = JSON.parse(response.body)
    rows = payload["data"] || []

    rows.filter_map { |row| normalize_row(row) }
  end

  def self.fetch(token)
    uri = URI(API_URL)
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{token}"

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
      http.request(req)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise SyncError, "API returned #{response.code}: #{response.body.to_s[0..200]}"
    end

    response
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError => e
    raise SyncError, "API request failed: #{e.message}"
  end

  def self.normalize_row(row)
    title = row["title"].to_s.strip
    brand = row["brand_title"].to_s.strip
    url_raw = row["url"].to_s.strip
    sezon_raw = row["seasonality"].to_s.strip

    return nil if title.empty? || brand.empty? || url_raw.empty?
    return nil if brand.casecmp("Тест").zero?

    url = url_raw.sub(%r{\Ahttps?://prokoleso\.ua/}, "").sub(%r{\Aua/}, "")
    { name: title, url: url, brand: brand, sezon: SEASON_MAP[sezon_raw] || sezon_raw }
  end

  def self.write_atomic(models)
    tmp = "#{OUTPUT_PATH}.tmp"
    File.write(tmp, JSON.pretty_generate(models))
    File.rename(tmp, OUTPUT_PATH)
  end
end
