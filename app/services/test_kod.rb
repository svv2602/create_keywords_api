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

  def export
    # извлекаем все записи
    seo_content_texts = SeoContentText.all

    # преобразуем данные в json
    json_data = seo_content_texts.to_json

    # создаем временный файл
    file = Tempfile.new('SeoContentTexts.json')
    file.write(json_data)
    file.rewind

    # отправляем файл пользователю
    send_file file.path, type: 'application/json', disposition: 'attachment', filename: 'SeoContentTexts.json'

    file.close
    file.unlink
  end


end