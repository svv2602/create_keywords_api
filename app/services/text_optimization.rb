# app/services/text_optimization.rb

module TextOptimization
  require_relative '../services/dictionaries/replaсe_keyword_tyres'

  def adjust_keyword_stuffing(str)
    current_stuffing = keyword_stuffing_for_all_words(str)
    adjustments = {}

    # Количество слов в тексте
    total_words = remove_html_tags(str).split.length

    KEYWORD_STUFFING_TEMPLATE.each do |keyword, desired_stuffing|
      # Текущая "тошнотность" для этого слова
      current_stuffing_level = current_stuffing[keyword] || 0

      # Рассчёт реального количества слов в тексте и желаемого количества слов
      current_word_count = (total_words * current_stuffing_level / 100).round
      target_word_count = (total_words * desired_stuffing['keyword_stuffing'] / 100).round
      adjustments[keyword] = {
        current_word_count: current_word_count,
        target_word_count: target_word_count,
        action: (target_word_count - current_word_count)
      }
    end

    adjustments
  end

  # Тошнота по Адвего: 30-40% - Учитывает не только количество повторений слов, но и их морфологические формы
  def keyword_stuffing_for_all_words(str)
    str = remove_html_tags(str)
    str = str.gsub("\n", ' ') # Add this line to replace new lines with spaces

    total_words = str.split.length

    results = {}
    WORD_FORMS.each do |word, forms|
      occurrences = forms.sum { |form| word_occurrences(str, form) }
      results[word] = (occurrences / total_words.to_f * 100).round(2)
    end
    results
  end

  def keyword_count_for_all_words(str)
    results = {}
    WORD_FORMS.each do |word, forms|
      occurrences = forms.sum { |form| word_occurrences(str, form) }
      results[word] = occurrences
    end
    results
  end

  def chars_count(str)
    str_test = remove_html_tags(str)
    str_test.scan(/[\p{L}\p{N}]/).length
  end

  def remove_html_tags(str)
    str.gsub(/<\/?[^>]*>/, "")
  end

  def word_occurrences(str, word)
    str.scan(/#{word}/i).length
  end

  # Рекомендуемый уровень тошнотности:
  # Классическая тошнота: 2,7-7% -  отношение количества повторений ключевого слова к общему количеству слов в тексте.
  def keyword_stuffing(str, word)
    total_words = remove_html_tags(str).split.length
    result = word_occurrences(str, word) / total_words.to_f * 100
    result = "Классическая тошнота: #{result.round(2)}%"
  end

  def replace_trash(str)
    str_new = str.gsub(/Dover's Auto Care/, 'PROKOLESO')
    str_new.gsub(/а боковой стене шин/, 'а боковине шин')
    str_new
  end

  def apply_replacements(text)
    replacements = KEYWORD_STUFFING_TEMPLATE

    adjustments = adjust_keyword_stuffing(text)
    if adjustments["шина"][:action]>0 && adjustments["резина"][:action]>0
      min_value = [adjustments["шина"][:action], adjustments["резина"][:action]].min
      text = replacements_keywords(text, replacements, "резина и шины", min_value)
    end

    result = text
    adjustments.each do |key, value|
      # puts "Ключ: #{key}, значение: #{value[:action]}"
      adjustments_new = adjust_keyword_stuffing(text)
      replacements_count_max = adjustments_new[key][:action]
      result = replacements_keywords(result, replacements, key, replacements_count_max)
    end

    result
  end

  def replacements_keywords(text, replacements, key, replacements_count_max)

    # puts "replacements == #{replacements}"
    # puts "replacements == #{key}"
    replacements_count = 0
    replacements[key]['replaces'].each do |old, new|
      break if replacements_count >= replacements_count_max
      while text =~ old
        break if replacements_count >= replacements_count_max
        text.sub!(old, new)
        replacements_count += 1
      end
    end
    text
  end



end
