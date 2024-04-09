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
    str_new.gsub(/Doudlestar/, 'Doublestar')

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
    # метод возвращает текст с заменами, заданными в KEYWORD_STUFFING_TEMPLATE, с учетом лимитов и регуляций,
    # установленных функцией adjust_keyword_stuffing.

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

  def prepositions_conjunctions
    # Весь список предлогов, союзов русского языка и служебных слов
    Set.new %w[http https prokoleso h1 h2 h3 h4 h5 h6 li ul ol p br а без благодаря близ в вблизи ввиду вглубь вдобавок вдоль взамен включая вкруг вместо вне внизу внутри внутрь во вовнутрь вокруг вопреки вперед впереди вплоть вразрез вроде вслед вследствие встречу втечение для до за из из-за из-под изнутри изо к как касательно кроме кругом между мимо на над надо наперекор наподобие напротив насчет насчёт несмотря ниже о об обо обок около от относительно ото перед пред предо прежде при применительно к про ради с среди средь у чрез через со под над после по без от до при то потому аль а будто как бы не если благо буде будто ведь выну да да дабы да что до тех пор пока ежели едва ежели едва ежелибо если бы еслить есмь затем что зато зачем и ибо идеже как как бы как будто как бы не когда коль коль скоро как какой бы ни лишь бы только на что не пусть чтобы нежели нежли не затем ли неужели ни но однако оттого отчего пока почему потому что притом притому причем промежду тем просто пусть раз разве как так тогда то есть точно тоже хоть хотя]
  end



  def standardization_of_punctuation(text)

    text = text.gsub(/(,|\:)\s*,/, ",") # двойные запятые
    text = text.gsub(/ \/ /, "") # убрать одиночные слеши
    text = text.gsub(/\.\s*,/, ".") # точка-пробелы-запятая
    text = text.gsub(/^[.!?]+/, '')  # Удалить лишние знаки препинания c начала строки
    text = text.gsub(/((\.|,|\:)\s*\.)+/, ".") # двойные точки или запятая-пробелы-точка
    text = text.gsub(/\s+/, ' ')
    text

  end


  def similar_sentences(text)
    # результат хеш с проверкой предложений на похожесть
    text = text.gsub(/(>|\u003e)\s*(\u003c|<)/, '><')
    sentences = text.split(/\.|!|\?|\\n|(<\/h\d>)/)

    number_rubric = 0
    number_str_of_rubric = 0
    # Создаем массив 'sentence_elements', где каждый элемент - это хэш с предложением и его массивом уникальных слов
    sentence_elements = sentences.map do |sentence|
      # puts sentence
      # Создаем временную копию предложения с заменой знаков препинания на пробелы
      txt = sentence.gsub(/[,;:'"(){}\[\]<>\/]/, ' ')
      if sentence =~ /\/h\d/
        number_rubric += 1
        number_str_of_rubric = 0
      else
        number_str_of_rubric += 1
      end

      # Очистить каждое слово от знаков препинания, привести его к нижнему регистру и проверить, что остаток содержит больше одного символа
      words = txt.split(' ').map do |word|
        word_without_last_two = word.strip[0...-2].downcase
        word_without_last_two unless prepositions_conjunctions.include?(word_without_last_two) or word_without_last_two.length <= 2
      end.uniq
      { sentence: sentence, words: words.compact, number_rubric: number_rubric, number_str_of_rubric: number_str_of_rubric }
    end

    # Для каждого элемента в sentence_elements, сравниваем его с остальными элементами
    comparisons = []
    sentence_elements.each_with_index do |element1, i|
      (i + 1...sentence_elements.length).each do |j|
        element2 = sentence_elements[j]
        common_words = element1[:words] & element2[:words]
        comparisons << { sentence_1: [element1[:sentence], element1[:number_rubric], element1[:number_str_of_rubric]],
                         sentence_2: [element2[:sentence], element2[:number_rubric], element2[:number_str_of_rubric]],
                         common_words: common_words }
      end
    end

    # Возвращаем все сравнения
    comparisons
  end

  def rating_sentence(arr_sentence)
    rating = 0
    str = arr_sentence[0]
    # number_rubric = arr_sentence[1]
    number_str_of_rubric = arr_sentence[2]

    if number_str_of_rubric <= 2
      rating = -5
    else
      # № предложения ближе к концу абзаца
      rating += 1 if number_str_of_rubric > 2
      # в предложении содержится размер, понижаем рейтинг
      rating += ((str =~ SEARCH_SIZE_1) || (str =~ SEARCH_SIZE_2)) ? -1 : 0
      # при равном рейтинге удаляем большее по символам
      rating += str.size/100
    end
    rating
  end


  def similar_sentences_delete(text)
    # удаление предложения с большим рейтингом
    hash = similar_sentences(text)
    hash.each do |el|
      str = rating_sentence(el[:sentence_2])< rating_sentence(el[:sentence_1]) ? el[:sentence_1][0]: el[:sentence_2][0]
      if el[:common_words].size >= 4 && text =~ /#{str}/
        text = text.sub(str, '')
        # puts "el = #{el.inspect}"
        # puts " = = ==  = = #{str}"
      end
    end
    text
  end





end
