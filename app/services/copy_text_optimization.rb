# app/services/copy_text_optimization.rb
require 'json'
# require_relative '../services/dictionaries/replace_keyword_tyres'
require_relative '../../app/services/content_writer'
require_relative '../../app/services/string_processing'


class CopyTextOptimization
  def count_title_text
    # Загрузка JSON файла
    file = File.read('/home/user/RubymineProjects/workspace_api/create_keywords_api/lib/template_texts/data.json')
    data_hash = JSON.parse(file)

    # Считаем количество каждого "TextType"
    text_type_count = count_text_type(data_hash)

    text_type_count
  end

  def count_text_type(data)
    count = Hash.new(0)
    if data.is_a?(Hash)
      data.each do |_key, value|
        count[value['TextType']] += 1 if value.is_a?(Hash) && value.has_key?('TextType')
        count.merge!(count_text_type(value)) { |_k, old_v, new_v| old_v + new_v } if value.is_a?(Hash) || value.is_a?(Array)
      end
    elsif data.is_a?(Array)
      data.each do |item|
        count.merge!(count_text_type(item)) { |_k, old_v, new_v| old_v + new_v }
      end
    end
    count
  end
end

test = CopyTextOptimization.new
result = test.count_title_text
puts "=" * 120
puts "result = #{result}"
puts "=" * 120