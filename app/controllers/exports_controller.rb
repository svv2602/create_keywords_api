class ExportsController < ApplicationController
  def export_text
    records = SeoContentText.all.as_json
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    send_data records.to_json, filename: "export_text_#{timestamp}.json"
  end
  def export_sentence
    records = SeoContentTextSentence.all.as_json
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    send_data records.to_json, filename: "export_sentence_#{timestamp}.json"
  end

  def count_records
    puts "Number of records in SeoContentTextSentence: #{SeoContentTextSentence.count}"
    puts "Number of records in SeoContentText: #{SeoContentText.count}"
    render json: { SeoContentText: "Number of records: #{SeoContentText.count}",
                   SeoContentTextSentence: "Number of records: #{SeoContentTextSentence.count}"
    }
  end

  def readme
    readme_file_path = Rails.root.join('README.md')
    readme_content = File.read(readme_file_path)
    render plain: readme_content
  end

end
