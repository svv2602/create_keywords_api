# app/services/text_length_manager.rb

class TextLengthManager
  # Целевые диапазоны длины отзывов (в словах)
  TARGET_LENGTHS = {
    very_short: [1, 10],      # "👍", "Норм", "Хорошие шины"
    short: [10, 40],          # Короткие отзывы
    medium: [30, 60],         # Средние отзывы  
    long: [50, 120]           # Развернутые отзывы
  }.freeze
  
  def initialize(target_range)
    @min_words = target_range[0]
    @max_words = target_range[1]
    @target_words = (@min_words + @max_words) / 2
  end
  
  def adjust_text_length(text, context = {})
    return text if text.blank?
    
    current_length = word_count(text)
    
    case
    when current_length < @min_words
      expand_text(text, @target_words - current_length, context)
    when current_length > @max_words
      compress_text(text, current_length - @target_words)
    else
      text # длина в норме
    end
  end
  
  def self.determine_target_length(type_review, original_text)
    original_length = word_count(original_text)
    
    case type_review
    when 1  # положительные - могут быть длиннее
      if original_length > 50
        TARGET_LENGTHS[:long]
      elsif original_length > 25
        TARGET_LENGTHS[:medium]
      else
        TARGET_LENGTHS[:short]
      end
    when -1 # негативные - часто короче и резче
      if original_length > 40
        TARGET_LENGTHS[:medium]
      else
        TARGET_LENGTHS[:short]
      end
    else    # нейтральные
      original_length > 30 ? TARGET_LENGTHS[:medium] : TARGET_LENGTHS[:short]
    end
  end
  
  private
  
  def expand_text(text, words_needed, context)
    return text if words_needed < 3
    
    expansions = generate_expansions(context, words_needed)
    return text if expansions.empty?
    
    # Вставляем расширения в текст
    sentences = text.split(/[.!?]+/).reject(&:empty?)
    return text if sentences.empty?
    
    # Выбираем подходящие расширения
    selected_expansions = select_expansions(expansions, words_needed)
    
    # Вставляем в подходящие места
    insert_expansions(sentences, selected_expansions).join('. ').strip + '.'
  end
  
  def compress_text(text, words_to_remove)
    return text if words_to_remove < 3
    
    sentences = text.split(/[.!?]+/).reject(&:empty?)
    return text if sentences.length <= 1
    
    # Стратегии сжатия
    sentences = remove_filler_sentences(sentences, words_to_remove)
    sentences = shorten_verbose_sentences(sentences, words_to_remove)
    sentences = combine_short_sentences(sentences)
    
    result = sentences.join('. ').strip
    result.empty? ? text : result + '.'
  end
  
  def generate_expansions(context, words_needed)
    expansions = []
    
    # Расширения на основе контекста
    if context[:brand] && rand < 0.4
      brand_expansions = [
        "#{context[:brand]} зарекомендовал себя хорошо",
        "До этого #{context[:brand]} не пробовал",
        "#{context[:brand]} - неплохой выбор"
      ]
      expansions.concat(brand_expansions)
    end
    
    if context[:car] && rand < 0.3
      car_expansions = [
        "На #{context[:car].downcase} сидят отлично",
        "Для #{context[:car].downcase} самое то",
        "#{context[:car]} с такими шинами ведет себя уверенно"
      ]
      expansions.concat(car_expansions)
    end
    
    # Общие расширения по типу отзыва
    case context[:type_review]
    when 1  # положительные
      positive_expansions = [
        "Рекомендую к покупке",
        "Доволен выбором",
        "Качество на высоте",
        "За эти деньги - отличный вариант",
        "Буду брать еще",
        "Друзьям тоже посоветовал"
      ]
      expansions.concat(positive_expansions)
      
    when -1 # негативные
      negative_expansions = [
        "Больше брать не буду",
        "Жалею о покупке", 
        "Ожидал большего",
        "За такие деньги можно найти лучше",
        "Разочарован результатом"
      ]
      expansions.concat(negative_expansions)
      
    else    # нейтральные
      neutral_expansions = [
        "В целом нормально",
        "Для своих задач подходят",
        "Ничего особенного, но работают",
        "Средний уровень качества"
      ]
      expansions.concat(neutral_expansions)
    end
    
    # Расширения по опыту использования
    experience_expansions = [
      "Проехал уже #{rand(5000..30000)} км",
      "Использую #{rand(6..24)} месяцев",
      "За #{rand(2..4)} сезона эксплуатации",
      "После #{rand(10000..50000)} км пробега"
    ]
    expansions.concat(experience_expansions) if rand < 0.3
    
    # Расширения по условиям использования
    if context[:season] && rand < 0.3
      season_name = case context[:season]
                   when 1 then 'летом'
                   when 2 then 'зимой'  
                   when 3 then 'круглый год'
                   else 'в сезон'
                   end
      
      season_expansions = [
        "#{season_name.capitalize} показали себя хорошо",
        "Для использования #{season_name} вполне подходят",
        "#{season_name.capitalize} ведут себя предсказуемо"
      ]
      expansions.concat(season_expansions)
    end
    
    expansions
  end
  
  def select_expansions(expansions, words_needed)
    return [] if expansions.empty?
    
    selected = []
    current_words = 0
    
    expansions.shuffle.each do |expansion|
      expansion_words = word_count(expansion)
      break if current_words + expansion_words > words_needed * 1.2
      
      selected << expansion
      current_words += expansion_words
      
      break if current_words >= words_needed * 0.8
    end
    
    selected
  end
  
  def insert_expansions(sentences, expansions)
    return sentences if expansions.empty?
    
    result = sentences.dup
    
    expansions.each_with_index do |expansion, index|
      # Определяем позицию для вставки
      if sentences.length == 1
        result << expansion
      else
        insert_pos = [result.length - 1, index + 1].min
        result.insert(insert_pos, expansion)
      end
    end
    
    result
  end
  
  def remove_filler_sentences(sentences, target_reduction)
    # Паттерны "мусорных" предложений для удаления
    filler_patterns = [
      /в целом/i,
      /подводя итог/i,
      /резюмируя/i,
      /хочу сказать/i,
      /в заключение/i,
      /как итог/i
    ]
    
    sentences.reject do |sentence|
      sentence_words = word_count(sentence)
      filler_patterns.any? { |pattern| sentence.match?(pattern) } &&
        sentence_words <= target_reduction
    end
  end
  
  def shorten_verbose_sentences(sentences, target_reduction)
    sentences.map do |sentence|
      next sentence if word_count(sentence) < 15
      
      # Убираем избыточные слова и фразы
      shortened = sentence
        .gsub(/,?\s*(кстати|между прочим|надо сказать)\s*,?/i, '')
        .gsub(/\s*(очень|весьма|крайне|довольно)\s+/i, ' ')
        .gsub(/\s+/, ' ')
        .strip
      
      shortened.empty? ? sentence : shortened
    end
  end
  
  def combine_short_sentences(sentences)
    return sentences if sentences.length < 3
    
    result = []
    i = 0
    
    while i < sentences.length
      current = sentences[i]
      
      # Если текущее предложение короткое, пытаемся объединить со следующим
      if word_count(current) < 8 && i + 1 < sentences.length
        next_sentence = sentences[i + 1]
        if word_count(next_sentence) < 12
          combined = "#{current}, #{next_sentence.downcase}"
          result << combined
          i += 2
          next
        end
      end
      
      result << current
      i += 1
    end
    
    result
  end
  
  def self.word_count(text)
    return 0 if text.blank?
    text.split(/\s+/).length
  end
  
  def word_count(text)
    self.class.word_count(text)
  end
end

