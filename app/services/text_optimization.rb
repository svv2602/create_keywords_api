# app/services/text_optimization.rb

module TextOptimization

  WORD_FORMS = {
    "шина" => ["шина", "шины", "шину", "шине", "шиною", "шинах", "шинами", "шинных"],
    "резина" => ["резина", "резины", "резину", "резине", "резиной", "резин", "резинами", "резинах"],
    "Киев" => ["Киев", "Киева", "Киеву", "Киеве"],
    "купить" => ["купить", "купил"],
    "колесо" => ["колесо", "колеса", "колесу", "колесе", "колесом",  "колесами", "колесах"],
    "покрышка" => ["покрышка", "покрышки", "покрышку", "покрышке", "покрышкой", "покрышках"],
    "автошина" => ["автошина", "автошины", "автошину", "автошине", "автошиной", "автошинами", "автошинах"],
    "доставка" => ["доставка", "доставки", "доставку", "доставке", "доставкой"],
    "размер" => ["размер", "размера", "размеру", "размере", "размером", "размеры", "размерами", "размерах"],
    "приобрести" => ["приобрести", "приобрел", "приобрели", "приобретя"],
    "выбрать" => ["выбрать", "выбрал", "выбрали", "выбрав"],
    "выбор" => ["выбор", "выбора", "выбору", "выборе", "выбором"],
    "покупка" => ["покупка", "покупки", "покупку", "покупке", "покупкой",  "покупками", "покупках"],
    "заказ" => ["заказ", "заказа", "заказу", "заказе", "заказом",  "заказы", "заказами", "заказах"],
    "купить шины" => ["купить шины", "купить шину"],
    "шины купить" => ["шины купить", "шину купить"],
    "купить резину" => ["купить резину"],
    "резину купить" => ["резину купить"],
    "заказать" => ["заказать", "заказал",  "заказали", "заказав"],
    "лето" => ['лета', 'лето', 'лету', 'летом', 'лете'],
    "летние" => ['летние', 'летних', 'летним',  'летними', 'летней'],
    "зима" => ['зима', 'зимы', 'зиме', 'зиму', 'зимой'],
    "зимние" => ['зимние', 'зимних', 'зимним','зимними', 'зимней'],
    "всесезонние" => ['всесезонные', 'всесезонных', 'всесезонным', 'всесезонными']
  }

  KEYWORD_STUFFING_TEMPLATE = {
    "шина" => 4.5,
    "резина" => 2.5,
    "Киев" => 0.6,
    "купить" => 0.7,
    # "колесо" => 1.0,
    # "покрышка" => 0.8,
    # "автошина" => 0.8,
    # "доставка" => 0.16,
    "размер" => 0.33,
    "выбор" => 0.5,
    # "покупка" => 0.2,
    "заказ" => 0.5,
    # "купить шины" => 0.3,
    # "шины купить" => 0.2,
    # "купить резину" => 0.2,
    # "резину купить" => 0.2,
    "заказать" => 0.15,
    "лето" => 0.66,
    "летние" => 0.33,
    "зима" => 0.66,
    "зимние" => 0.33,
    # "всесезонние" => 0.15
  }

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
      target_word_count = (total_words * desired_stuffing / 100).round
      target_word_count - current_word_count < 0 ? action = "убрать " : action = "добавить "
      adjustments[keyword] = {
        current_word_count: current_word_count,
        target_word_count: target_word_count,
        # action: action + (target_word_count - current_word_count).to_s
        action: target_word_count - current_word_count
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






end
