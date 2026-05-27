require "csv"
require "json"

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
    if ENV["DRY_RUN"] == "1"
      begin
        models = TyreModelsSync.preview
        puts "[DRY RUN] would write #{models.size} models to #{TyreModelsSync::OUTPUT_PATH}"
        puts JSON.pretty_generate(models.first(3))
      rescue TyreModelsSync::SyncError => e
        warn e.message
        exit 1
      end
    else
      begin
        count = TyreModelsSync.sync!
        puts "Synced #{count} models from API to #{TyreModelsSync::OUTPUT_PATH}"
      rescue TyreModelsSync::SyncError => e
        warn e.message
        exit 1
      end
    end
  end
end
