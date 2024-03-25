module StringProcessingServices
  def array_after_error_from_json
    hash = data_json_to_hash
    content_last_element_hash = last_element_hash_json(hash)

    last_content_type = ""
    last_rec = SeoContentText.order(:created_at).last

    last_content_type = last_rec.content_type if last_rec

    unless last_content_type == content_last_element_hash
      specific_value = content_last_element_hash
      delete_flag = false

      hash.delete_if do |key, value|
        if value == specific_value
          delete_flag = true
        end
        !delete_flag
      end
    end
    return hash

  end

  def last_element_hash_json(hash)
    text_title = ''
    last_key_value_pair = hash.to_a.last
    if last_key_value_pair
      sub_hash = last_key_value_pair[1]
      text_title = sub_hash["TextTitle"]
    end
    text_title
  end

end