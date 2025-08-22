# app/services/text_naturalizer.rb

class TextNaturalizer
  include ServiceReview
  
  def initialize
    @sentiment_patterns = load_sentiment_patterns
    @conversational_replacements = load_conversational_replacements
    @personal_phrases = load_personal_phrases
  end
  
  def naturalize_review(text, context = {})
    return text if text.blank? || text.length < 10
    
    # Пайплайн обработки для естественности
    text = remove_ai_artifacts(text)
    text = improve_conversational_style(text)
    text = add_personal_touches(text, context)
    text = vary_sentence_structure(text)
    text = add_natural_hesitations(text)
    text = adjust_punctuation_naturally(text)
    text = final_cleanup(text)
    
    text
  end
  
  def improve_problematic_parts(text, context = {})
    # Легкая версия для гибридного подхода
    text = remove_ai_artifacts(text)
    text = improve_conversational_style(text)
    text = final_cleanup(text)
    text
  end
  
  private
  
  def remove_ai_artifacts(text)
    # Удаляем типичные AI-фразы
    ai_phrases = [
      /в целом,?\s*я\s*(бы\s*)?рекомендую/i,
      /в заключение\s*(хочу\s*сказать)?/i,
      /подводя\s*итог/i,
      /резюмируя/i,
      /безусловно\s*рекомендую/i,
      /данные\s*шины/i,
      /представленная\s*модель/i,
      /рассматриваемый\s*продукт/i
    ]
    
    ai_phrases.each { |phrase| text.gsub!(phrase, '') }
    text.strip
  end
  
  def improve_conversational_style(text)
    # Заменяем формальные конструкции на разговорные
    @conversational_replacements.each do |formal, casual_options|
      if text.include?(formal)
        casual = casual_options.is_a?(Array) ? casual_options.sample : casual_options
        text.gsub!(formal, casual)
      end
    end
    text
  end
  
  def add_personal_touches(text, context)
    return text unless rand < 0.4 # 40% вероятность добавления личных деталей
    
    personal_additions = []
    
    # Добавляем информацию об автомобиле
    if context[:car] && rand < 0.3
      personal_additions << "У меня #{context[:car].downcase}"
    end
    
    # Добавляем опыт использования
    if rand < 0.4
      months = rand(6..36)
      personal_additions << "За #{months} #{months_word(months)} использования проблем не было"
    end
    
    # Добавляем сравнения
    if context[:type_review] == 1 && rand < 0.3
      personal_additions << "По сравнению с предыдущими шинами - заметная разница"
    end
    
    # Добавляем условия эксплуатации
    if rand < 0.3
      conditions = ['в основном город', 'много трассы', 'смешанный режим', 'активная езда'].sample
      personal_additions << "Езжу #{conditions}"
    end
    
    return text if personal_additions.empty?
    
    # Вставляем дополнения в текст
    sentences = text.split(/[.!?]+/).reject(&:empty?)
    return text if sentences.empty?
    
    personal_additions.each_with_index do |addition, index|
      insert_position = [sentences.length - 1, index + 1].min
      sentences.insert(insert_position, addition)
    end
    
    sentences.join('. ').strip + '.'
  end
  
  def vary_sentence_structure(text)
    sentences = text.split(/[.!?]+/).reject(&:empty?)
    return text if sentences.length < 2
    
    sentences.map.with_index do |sentence, index|
      sentence = sentence.strip
      next sentence if sentence.length < 10
      
      # Случайно изменяем структуру предложений
      case rand(5)
      when 0
        add_parenthetical_remark(sentence) if index > 0
      when 1
        add_discourse_marker(sentence) if index > 0
      when 2
        make_more_colloquial(sentence)
      else
        sentence
      end
    end.join('. ').strip + '.'
  end
  
  def add_natural_hesitations(text)
    return text unless rand < 0.25 # 25% вероятность
    
    hesitations = ['ну', 'вот', 'короче', 'в общем', 'кстати', 'собственно']
    
    sentences = text.split(/[.!?]+/).reject(&:empty?)
    return text if sentences.empty?
    
    target_sentence = rand(sentences.length)
    hesitation = hesitations.sample
    
    sentences[target_sentence] = sentences[target_sentence].strip
    sentences[target_sentence] = "#{hesitation}, #{sentences[target_sentence].downcase}"
    
    sentences.join('. ').strip + '.'
  end
  
  def adjust_punctuation_naturally(text)
    # Естественная пунктуация
    text = text.gsub(/\.\s*([А-ЯЁ])/) do |match|
      rand < 0.1 ? "... #{$1}" : match  # иногда многоточие вместо точки
    end
    
    # Случайные восклицательные знаки для эмоций
    text = text.gsub(/(отлично|супер|класс|здорово|ужас|кошмар)\.?/i) do |match|
      word = $1
      rand < 0.6 ? "#{word}!" : "#{word}."
    end
    
    text
  end
  
  def final_cleanup(text)
    text.gsub(/\s+/, ' ')           # убираем лишние пробелы
        .gsub(/\.\s*\.+/, '.')      # убираем двойные точки
        .gsub(/\s+([,.!?])/, '\1')  # убираем пробелы перед знаками препинания
        .gsub(/([.!?])\s*([.!?])/, '\1') # убираем дублирующие знаки
        .strip
  end
  
  def add_parenthetical_remark(sentence)
    remarks = [
      'правда',
      'кстати',
      'между прочим',
      'надо сказать'
    ]
    
    "#{sentence} (#{remarks.sample})"
  end
  
  def add_discourse_marker(sentence)
    markers = [
      'Кстати',
      'К тому же',
      'Плюс ко всему',
      'Да и вообще'
    ]
    
    "#{markers.sample}, #{sentence.downcase}"
  end
  
  def make_more_colloquial(sentence)
    # Делаем предложение более разговорным
    sentence.gsub(/очень хорошо/i, ['классно', 'отлично', 'супер'].sample)
            .gsub(/очень плохо/i, ['ужасно', 'кошмар', 'жесть'].sample)
            .gsub(/рекомендую/i, ['советую', 'посоветую'].sample)
  end
  
  def months_word(count)
    case count
    when 1
      'месяц'
    when 2..4
      'месяца'  
    else
      'месяцев'
    end
  end
  
  def load_sentiment_patterns
    {
      positive: /отлично|супер|класс|здорово|хорошо|прекрасно|замечательно/i,
      negative: /плохо|ужасно|кошмар|отвратительно|жалею|разочарован/i,
      neutral: /нормально|неплохо|средне|приемлемо|сойдёт/i
    }
  end
  
  def load_conversational_replacements
    {
      'приобрёл' => %w[купил взял приобрёл],
      'приобрел' => %w[купил взял приобрел],
      'использую' => %w[езжу катаюсь пользуюсь],
      'эксплуатирую' => %w[езжу катаюсь],
      'рекомендую' => %w[советую посоветую рекомендую],
      'отличные шины' => ['хорошая резина', 'неплохие шины', 'годная резина', 'отличные шины'],
      'превосходные характеристики' => ['хорошо себя показали', 'работают отлично', 'ведут себя прилично'],
      'данная модель' => ['эти шины', 'такая резина', 'эта модель'],
      'в процессе эксплуатации' => ['при езде', 'во время поездок', 'на дороге'],
      'осуществляю' => ['делаю', 'провожу']
    }
  end
  
  def load_personal_phrases
    [
      'У меня опыт вождения #{years} лет',
      'Езжу в основном по #{road_type}',
      'За #{experience} месяцев использования',
      'По сравнению с предыдущими шинами',
      'На моем #{car_type}',
      'В моих условиях эксплуатации'
    ]
  end
end

