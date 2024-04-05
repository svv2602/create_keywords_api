class ExportsController < ApplicationController
  include ServiceTable
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

  def clear_tables_texts

    case params[:table].to_i
    when 1
      SeoContentText.delete_all
    when 2
      SeoContentTextSentence.delete_all
    when 12
      SeoContentTextSentence.delete_all
      SeoContentText.delete_all
    end
    render plain: "Все удалено "
  end

  def count_records
    puts "Number of records in SeoContentTextSentence: #{SeoContentTextSentence.count}"
    puts "Number of records in SeoContentText: #{SeoContentText.count}"
    render json: { SeoContentText: "#{SeoContentText.count}",
                   SeoContentTextSentence: "#{SeoContentTextSentence.count}"
    }
  end

  def readme
    readme_file_path = Rails.root.join('README.md')
    readme_content = File.read(readme_file_path)
    render plain: readme_content
  end

  def control_records
    # сделать очистку таблиц
    table = 'seo_content_text_sentences'
    remove_empty_sentences(table)
    # replace_errors_size(table)
    repeat_sentences_generation(table)
    render plain: "удалил весь мусор"

  end

end
