require "csv"
require "json"

namespace :tyre_models do
  desc "Import tyre models from CSV to JSON. Usage: rake tyre_models:import_csv[lib/model2026-02.csv]"
  task :import_csv, [:path] => :environment do |_t, args|
    csv_path = args[:path] || "lib/model2026-02.csv"

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
end
