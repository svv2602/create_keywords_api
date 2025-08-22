# app/services/smart_emoji_manager.rb

class SmartEmojiManager
  def initialize
    # Расширенные наборы эмодзи по контексту
    @emoji_sets = {
      positive: {
        performance: %w[🚀 ⚡ 💪 🔥 ⭐],
        satisfaction: %w[😊 😍 🥰 👌 👍],
        recommendation: %w[💯 ✅ 👏 🙌 🎯],
        winter_specific: %w[❄️ 🧊 ⛄ 🌨️],
        summer_specific: %w[☀️ 🌞 🏖️ 🔆],
        general: %w[😊 👍 ✨ 🔥 💪]
      },
      negative: {
        disappointment: %w[😞 😤 🙄 😠 💔],
        problems: %w[⚠️ 🚫 ❌ 💸 😬],
        warning: %w[🔴 ⛔ 🚨],
        general: %w[😞 😤 ❌ 😠]
      },
      neutral: {
        okay: %w[🤷 😐 👌 ✋],
        thinking: %w[🤔 💭 🧐],
        general: %w[🤷 😐 👌]
      }
    }
    
    # Паттерны для анализа текста
    @text_patterns = {
      performance: /быстро|скорость|разгон|торможение|управля|маневр|устойчив/i,
      satisfaction: /(доволен|радует|нравится|отлично|супер|класс|здорово)/i,
      recommendation: /(советую|рекомендую|покупайте|берите|советовал)/i,
      problems: /(проблем|плохо|ужасно|разочарован|жалею|кошмар)/i,
      winter: /(зим|снег|лед|мороз|холод)/i,
      summer: /(лет|жар|солнц|асфальт|тепл)/i,
      price: /(деньги|цена|стоимость|дорого|дешево|бюджет)/i
    }
  end
  
  def add_contextual_emoji(text, type_review, context = {})
    return text unless should_add_emoji?(text, type_review)
    
    # Анализируем содержание текста для выбора подходящих эмодзи
    emoji_context = analyze_text_for_emoji(text, context)
    selected_emojis = select_appropriate_emojis(type_review, emoji_context, context)
    
    return text if selected_emojis.empty?
    
    # Добавляем эмодзи с умным позиционированием
    place_emojis_smartly(text, selected_emojis)
  end
  
  private
  
  def should_add_emoji?(text, type_review)
    # Более умные условия для добавления эмодзи
    return false if text.length < 15  # слишком короткий текст
    return false if text.count('!') > 3  # уже очень эмоциональный
    return false if text.match?(/[😀-🙏🚀-🛿]/u)  # уже есть эмодзи
    
    # Базовая вероятность в зависимости от типа отзыва
    probability = case type_review
                 when 1   # положительные
                   0.45
                 when -1  # негативные  
                   0.25
                 else     # нейтральные
                   0.15
                 end
    
    # Корректируем вероятность по длине текста
    word_count = text.split(/\s+/).length
    if word_count > 50
      probability *= 0.8  # длинные тексты - меньше эмодзи
    elsif word_count < 20
      probability *= 1.3  # короткие тексты - больше эмодзи
    end
    
    rand < probability
  end
  
  def analyze_text_for_emoji(text, context)
    analysis = {}
    
    # Анализируем текст по паттернам
    @text_patterns.each do |key, pattern|
      analysis[key] = text.match?(pattern)
    end
    
    # Добавляем контекстную информацию
    analysis[:season_context] = context[:season] if context[:season]
    analysis[:language] = context[:language] || 'ru'
    analysis[:is_question] = text.include?('?')
    analysis[:is_exclamatory] = text.count('!') > 0
    analysis[:word_count] = text.split(/\s+/).length
    
    analysis
  end
  
  def select_appropriate_emojis(type_review, emoji_context, context)
    selected = []
    max_emojis = determine_max_emojis(type_review, emoji_context[:word_count])
    
    case type_review
    when 1  # положительные отзывы
      selected.concat(select_positive_emojis(emoji_context))
      
    when -1  # негативные отзывы
      selected.concat(select_negative_emojis(emoji_context))
      
    else  # нейтральные отзывы
      selected.concat(select_neutral_emojis(emoji_context))
    end
    
    # Добавляем сезонные эмодзи если уместно
    selected.concat(select_seasonal_emojis(emoji_context, type_review))
    
    # Ограничиваем количество и убираем дубликаты
    selected.uniq.take(max_emojis)
  end
  
  def select_positive_emojis(emoji_context)
    selected = []
    
    if emoji_context[:performance]
      selected << @emoji_sets[:positive][:performance].sample
    elsif emoji_context[:satisfaction]
      selected << @emoji_sets[:positive][:satisfaction].sample
    elsif emoji_context[:recommendation]
      selected << @emoji_sets[:positive][:recommendation].sample
    else
      selected << @emoji_sets[:positive][:general].sample
    end
    
    # Дополнительные эмодзи для очень положительных отзывов
    if emoji_context[:satisfaction] && emoji_context[:recommendation] && rand < 0.4
      selected << @emoji_sets[:positive][:satisfaction].sample
    end
    
    selected
  end
  
  def select_negative_emojis(emoji_context)
    selected = []
    
    if emoji_context[:problems]
      selected << @emoji_sets[:negative][:problems].sample
    else
      selected << @emoji_sets[:negative][:disappointment].sample
    end
    
    # Предупреждающие эмодзи для серьезных проблем
    if emoji_context[:problems] && emoji_context[:word_count] > 30 && rand < 0.3
      selected << @emoji_sets[:negative][:warning].sample
    end
    
    selected
  end
  
  def select_neutral_emojis(emoji_context)
    selected = []
    
    if emoji_context[:thinking] || emoji_context[:is_question]
      selected << @emoji_sets[:neutral][:thinking].sample
    else
      selected << @emoji_sets[:neutral][:okay].sample
    end
    
    selected
  end
  
  def select_seasonal_emojis(emoji_context, type_review)
    return [] if type_review == -1  # не добавляем сезонные эмодзи к негативным отзывам
    return [] unless rand < 0.25    # только в 25% случаев
    
    selected = []
    
    # По сезону из контекста
    case emoji_context[:season_context]
    when 2  # зимние шины
      selected << @emoji_sets[:positive][:winter_specific].sample if rand < 0.4
    when 1  # летние шины
      selected << @emoji_sets[:positive][:summer_specific].sample if rand < 0.4
    end
    
    # По упоминаниям в тексте (приоритетнее контекста)
    if emoji_context[:winter]
      selected << @emoji_sets[:positive][:winter_specific].sample
    elsif emoji_context[:summer]
      selected << @emoji_sets[:positive][:summer_specific].sample
    end
    
    selected
  end
  
  def place_emojis_smartly(text, emojis)
    return text if emojis.empty?
    
    # Стратегии размещения эмодзи
    placement_strategy = determine_placement_strategy(text, emojis.length)
    
    case placement_strategy
    when :end_of_text
      "#{text.rstrip} #{emojis.join(' ')}"
    when :new_line
      "#{text.rstrip}\n#{emojis.join(' ')}"
    when :inline
      place_inline_emojis(text, emojis)
    when :scattered
      scatter_emojis_in_text(text, emojis)
    else
      "#{text.rstrip} #{emojis.join(' ')}"
    end
  end
  
  def determine_placement_strategy(text, emoji_count)
    word_count = text.split(/\s+/).length
    
    # Для коротких текстов - просто в конце
    return :end_of_text if word_count < 15
    
    # Для длинных текстов - встраиваем
    return :inline if word_count > 40 && emoji_count <= 2
    
    # Для средних текстов - в зависимости от количества эмодзи
    if emoji_count > 2
      :scattered
    elsif rand < 0.3
      :new_line
    else
      :end_of_text
    end
  end
  
  def place_inline_emojis(text, emojis)
    sentences = text.split(/[.!?]+/).reject(&:empty?)
    return text if sentences.length < 2
    
    result_sentences = sentences.dup
    
    emojis.each_with_index do |emoji, index|
      # Находим подходящее предложение для эмодзи
      target_index = find_suitable_sentence_for_emoji(result_sentences, emoji, index)
      
      if target_index && target_index < result_sentences.length
        result_sentences[target_index] = "#{result_sentences[target_index].strip} #{emoji}"
      end
    end
    
    # Восстанавливаем структуру текста
    result_sentences.join('. ').strip + 
      (text.end_with?('.', '!', '?') ? '' : '.')
  end
  
  def scatter_emojis_in_text(text, emojis)
    # Распределяем эмодзи по тексту
    sentences = text.split(/[.!?]+/).reject(&:empty?)
    return "#{text} #{emojis.join(' ')}" if sentences.length < emojis.length
    
    # Равномерно распределяем эмодзи
    step = sentences.length.to_f / emojis.length
    
    emojis.each_with_index do |emoji, index|
      target_index = (step * index).round
      target_index = [target_index, sentences.length - 1].min
      
      sentences[target_index] = "#{sentences[target_index].strip} #{emoji}"
    end
    
    sentences.join('. ').strip + 
      (text.end_with?('.', '!', '?') ? '' : '.')
  end
  
  def find_suitable_sentence_for_emoji(sentences, emoji, emoji_index)
    # Логика поиска подходящего предложения для конкретного эмодзи
    
    # Для эмодзи производительности ищем соответствующие предложения
    if @emoji_sets[:positive][:performance].include?(emoji)
      sentences.each_with_index do |sentence, index|
        return index if sentence.match?(@text_patterns[:performance])
      end
    end
    
    # Для эмодзи удовлетворения
    if @emoji_sets[:positive][:satisfaction].include?(emoji)
      sentences.each_with_index do |sentence, index|
        return index if sentence.match?(@text_patterns[:satisfaction])
      end
    end
    
    # По умолчанию - равномерное распределение
    target_index = (sentences.length.to_f / (emoji_index + 1)).round - 1
    [target_index, 0].max
  end
  
  def determine_max_emojis(type_review, word_count)
    base_count = case type_review
                when 1   # положительные могут быть более эмоциональными
                  word_count > 50 ? rand(2..3) : rand(1..2)
                when -1  # негативные - сдержаннее
                  word_count > 40 ? rand(1..2) : 1
                else     # нейтральные - минимум
                  1
                end
    
    # Корректируем по длине текста
    if word_count < 20
      [base_count, 1].min
    elsif word_count > 80
      [base_count, 3].min
    else
      base_count
    end
  end
end

