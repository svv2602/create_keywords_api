require "csv"
require "json"
require "net/http"
require "uri"

namespace :tyre_models do
  desc "Import tyre models from CSV to JSON. Usage: rake tyre_models:import_csv[lib/model-22-05-2026.csv]"
  task :import_csv, [:path] => :environment do |_t, args|
    csv_path = args[:path] || "lib/model-22-05-2026.csv"

    unless File.exist?(csv_path)
      puts "File not found: #{csv_path}"
      exit 1
    end

    season_map = {
      "лето" => "letnie",
      "зима" => "zimnie",
      "всесезонка" => "vsesezonie"
    }

    models = []

    CSV.foreach(csv_path, headers: true) do |row|
      url_raw = row[0].to_s.strip
      sezon_raw = row[1].to_s.strip
      brand = row[2].to_s.strip
      name = row[3].to_s.strip

      next if url_raw.empty? || brand.empty? || name.empty?

      # URL: remove https://prokoleso.ua/ and optional /ua/ prefix
      url = url_raw
        .sub(%r{\Ahttps?://prokoleso\.ua/}, "")
        .sub(%r{\Aua/}, "")

      sezon = season_map[sezon_raw.downcase] || sezon_raw

      models << { name: name, url: url, brand: brand, sezon: sezon }
    end

    output_path = Rails.root.join("lib", "tyre_models.json").to_s
    File.write(output_path, JSON.pretty_generate(models))

    puts "Imported #{models.size} models to #{output_path}"
  end

  desc "Sync tyre models from prokoleso.ua API to lib/tyre_models.json. Set DRY_RUN=1 to preview."
  task sync_from_api: :environment do
    api_url = "https://prokoleso.ua/api/v1/catalog/top-models"
    token = ENV["PROKOLESO_API_TOKEN"]

    if token.nil? || token.empty?
      warn "PROKOLESO_API_TOKEN is not set"
      exit 1
    end

    season_map = {
      "Летние шины" => "letnie",
      "Зимние шины" => "zimnie",
      "Всесезонные шины" => "vsesezonie"
    }

    uri = URI(api_url)
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{token}"

    begin
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
        http.request(req)
      end
    rescue StandardError => e
      warn "API request failed: #{e.message}"
      exit 1
    end

    unless response.is_a?(Net::HTTPSuccess)
      warn "API returned #{response.code}: #{response.body.to_s[0..200]}"
      exit 1
    end

    payload = JSON.parse(response.body)
    rows = payload["data"] || []

    models = rows.filter_map do |row|
      title = row["title"].to_s.strip
      brand = row["brand_title"].to_s.strip
      url_raw = row["url"].to_s.strip
      sezon_raw = row["seasonality"].to_s.strip

      next if title.empty? || brand.empty? || url_raw.empty?
      next if brand.casecmp("Тест").zero?

      url = url_raw
        .sub(%r{\Ahttps?://prokoleso\.ua/}, "")
        .sub(%r{\Aua/}, "")

      sezon = season_map[sezon_raw] || sezon_raw

      { name: title, url: url, brand: brand, sezon: sezon }
    end

    if models.empty?
      warn "API returned no valid records; existing JSON kept intact"
      exit 1
    end

    output_path = Rails.root.join("lib", "tyre_models.json").to_s

    if ENV["DRY_RUN"] == "1"
      puts "[DRY RUN] would write #{models.size} models to #{output_path}"
      puts JSON.pretty_generate(models.first(3))
      next
    end

    tmp_path = "#{output_path}.tmp"
    File.write(tmp_path, JSON.pretty_generate(models))
    File.rename(tmp_path, output_path)

    puts "Synced #{models.size} models from API to #{output_path}"
  end
end
