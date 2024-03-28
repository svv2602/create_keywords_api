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

  def trash_words(text)
    result = 0
    marker1 = "копирайт"
    marker2 = "моск(|о)в|росс"
    regexp_string = "(?:#{marker1}|#{marker2})"
    regexp = Regexp.new(regexp_string, 1)

    percentage =  text =~ regexp ? 1 : 0

    percentage
  end

  def remove_small_sentences(original_text, min_count = 3)
    # Весь список предлогов и союзов русского языка
    prepositions_conjunctions = Set.new %w[а без благодаря близ в вблизи ввиду вглубь вдобавок вдоль взамен включая вкруг вместо вне внизу внутри внутрь во вовнутрь вокруг вопреки вперед впереди вплоть вразрез вроде вслед вследствие встречу втечение для до за из из-за из-под изнутри изо к как касательно кроме кругом между мимо на над надо наперекор наподобие напротив насчет насчёт несмотря ниже о об обо обок около от относительно ото перед пред предо прежде при применительно к про ради с среди средь у чрез через со под над после по без от до при то потому аль а будто как бы не если благо буде будто ведь выну да да дабы да что до тех пор пока ежели едва ежели едва ежелибо если бы еслить есмь затем что зато зачем и ибо идеже как как бы как будто как бы не когда коль коль скоро как какой бы ни лишь бы только на что не пусть чтобы нежели нежли не затем ли неужели ни но однако оттого отчего пока почему потому что притом притому причем промежду тем просто пусть раз разве как так тогда то есть точно тоже хоть хотя]

    # Разбить текст на предложения используя точку, восклицательный и вопросительный знак в качестве разделителей
    sentences = original_text.split(/[.!?]/)
    sentences.each do |sentence|
      # Создание временной копии исходного текста с заменой знаков препинания на пробелы
      text = sentence.gsub(/[,;:'"(){}\[\]<>]/, ' ')
      # Очистить каждое слово от знаков препинания и привести его к нижнему регистру
      words = text.split(' ').reject { |word| prepositions_conjunctions.include?(word.strip.downcase) }.uniq
      if words.count <= min_count
        original_text.sub!(sentence, '')
      end
    end
    original_text.gsub!(/\.+/, '.')
    # Удалить лишние знаки препинания c начала строки
    original_text.sub!(/^[.!?]+/, '')
    # Удалить пробельные символы с начала и конца строки
    original_text.strip
  end


end

test = CopyTextOptimization.new
result = test.count_title_text
puts "=" * 120
puts "result = #{result}"
puts "=" * 120

# text = " [size] летние покрышки отличает прочная конструкция, которая сохраняет свою форму даже при высоких температурах, не подвергаясь износу. Встроенные компоненты материала направлены на уменьшение сопротивления качению в условиях летнего периода, что способствует экономии топлива и снижению выбросов harmful emissions in the atmosphere around us fuel consumption and reduce harmful emissions into the atmosphere. The tread pattern of these tires typically features shallow grooves and a minimal number of lateral slits to improve handling and provide acoustic comfort."
text = " size [size] size  моС size летние. [size] летние моС квский покрышки R18 Kumho, HANKOOK отличает прочная конструкция. И я,апаппа. летние моС квский покрышки R18 Kumho, HANKOOK"



result = test.remove_small_sentences(text)
puts "result = #{result}"