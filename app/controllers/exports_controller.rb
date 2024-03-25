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
end
