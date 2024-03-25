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


  def add_new_el_to_hash(max_replacements, selected_max_elements)
    if max_replacements["шина"][:action] > 0 && max_replacements["резина"][:action] > 0
      min_value = [max_replacements["шина"][:action], max_replacements["резина"][:action]].min
      selected_max_elements["резина и шины"] = {}
      selected_max_elements["резина и шины"][:action] = min_value
    end
    selected_max_elements
  end

  def replace_text_by_hash(text)
    hash = KEYWORD_STUFFING_TEMPLATE
    sentences = text.split(/\.|!|\?|\\n/)
    count = Hash.new(0)


    max_replacements = adjust_keyword_stuffing(text)
    selected_max_elements = max_replacements.select { |key, value| value[:action] > 0 }
    selected_max_elements = add_new_el_to_hash(max_replacements, selected_max_elements)
    grup = false

    sentences.map! do |sentence|
      hash.each do |key, replacement|

        if selected_max_elements[key] && selected_max_elements[key][:action] > 0
          was_replaced = false
          replacement['replaces'].each do |k, rpl|
            next if grup == true && replacement['grup'] == 'tyres'
            sentence = sentence.sub(k) do |match|
              count[key] += 1

              if count[key] >= selected_max_elements[key][:action]
                match
              else
                grup = true if replacement['grup'] == 'tyres'
                was_replaced = true
                if key == "резина и шины"
                  count["резина"] += 1
                  count["шина"] += 1
                end
                rpl.is_a?(Array) ? rpl.sample : rpl
              end
            end
            break if was_replaced
          end
        end
      end
      grup = false
      sentence
    end

    sentences.join('.')
  end

  def replace_text_by_hash_minus(text)
    hash = KEYWORD_STUFFING_TEMPLATE
    sentences = text.split(/\.|!|\?|\\n/)
    count = Hash.new(0)

    max_replacements = adjust_keyword_stuffing(text)
    selected_max_elements = max_replacements.select { |key, value| value[:action] < 0 }

    sentences.map! do |sentence|
      hash.each do |key, replacement|
        if selected_max_elements[key] && selected_max_elements[key][:action] < 0
          was_replaced = false
          replacement['sinonims'].each do |k, rpl|
            # next if grup == true && replacement['grup'] == 'tyres'
            sentence = sentence.sub(k) do |match|
              count[key] -= 1

              if count[key] <= selected_max_elements[key][:action]
                match
              else
                was_replaced = true
                rpl.is_a?(Array) ? rpl.sample : rpl
              end
            end
            break if was_replaced
          end
        end
      end
      sentence
    end

    sentences.join('.')
  end






end
