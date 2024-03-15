# app/services/test_kod.rb


# Для копирования базы записей запустить:
# rails console
# TestKod.export_data_to_json

class TestKod
  # lib/template_texts/finished_texts
  def self.export_data_to_json
    require 'json'

    time_stamp = Time.now.strftime("%Y%m%d-%H%M%S")
    file_path = Rails.root.join('lib', 'template_texts/finished_texts', "texts_#{time_stamp}.json")

    texts = SeoContentText.all

    # Преобразовываем данные в JSON, используя `as_json`
    json_data = texts.as_json

    # Сохраняем данные в файл JSON
    File.open(file_path, "w") do |file|
      file.write(JSON.pretty_generate(json_data))
    end
  end
end