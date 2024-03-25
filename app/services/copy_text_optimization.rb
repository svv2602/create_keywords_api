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
  # ==================================
  def percent_of_latin_chars(text)
    # Подсчет латинских символов в тексте
    marker = "Z|W|Y|\(Y\)|ZR|XL|Reinforced|SL|Standard\sLoad|AS|All-Season|AT|All-Terrain|MT|M\+S|M/S|LT|P|C|ST|RF|DOT|ECE|ISO|UTQG|M&S|ATP|AWD"
    # exclude_words = arr_name_brand_uniq
    exclude_words = "kumho|tigar|HANKOOK"
    # Создаем регулярное выражение, объединяя все слова и регулярные выражения, из которых нужно избавиться
    regexp_string = "\\b(?:size|prokoleso|#{exclude_words.split(' ').join("|")}|ua|#{marker})\\b"
    regexp = Regexp.new(regexp_string, "i")

    filtered_text = text.gsub(regexp, '') # удаляем указанные слова из текста
    filtered_text = filtered_text.gsub(/(R|r)(|\s*)\d+/, '')

    latin_letters = filtered_text.scan(/[a-zA-Z]/).size
    total_chars = text.gsub(/\s+/, "").size
    percentage = (latin_letters.to_f / total_chars) * 100

    puts "Percentage of Latin letters: #{percentage.round(2)}%"
  end
end

test = CopyTextOptimization.new
result = test.count_title_text
puts "=" * 120
puts "result = #{result}"
puts "=" * 120

# text = " [size] летние покрышки отличает прочная конструкция, которая сохраняет свою форму даже при высоких температурах, не подвергаясь износу. Встроенные компоненты материала направлены на уменьшение сопротивления качению в условиях летнего периода, что способствует экономии топлива и снижению выбросов harmful emissions in the atmosphere around us fuel consumption and reduce harmful emissions into the atmosphere. The tread pattern of these tires typically features shallow grooves and a minimal number of lateral slits to improve handling and provide acoustic comfort."
text = " [size] летние покрышки R18 Kumho, HANKOOK отличает прочная конструкция"


test.percent_of_latin_chars(text)
