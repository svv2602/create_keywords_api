# app/services/string_processing.rb


module StringProcessing
  require_relative '../../app/services/dictionaries/const_regex'
  def arr_size_name_min(ww, hh, rr, i)
    result = ''

    case i % 10
    when 1
      result = "#{ww} #{hh}r#{rr}"
    when 2
      result = "#{ww}/#{hh} р#{rr}"
    when 3
      result = "#{ww} #{hh} r#{rr}"
    when 4
      result = "#{ww}/#{hh} R#{rr}"
    when 5
      result = "#{ww} #{hh} R#{rr}"
    when 6
      result = "#{ww}x#{hh} R#{rr}"
    when 7
      result = "#{ww}/#{hh} на R#{rr}"
    when 8
      result = "#{ww}/#{hh} на #{rr}"
    else
      result = "#{ww} #{hh} #{rr}"
    end
    result
  end

  def arr_size_to_error
    url_hash = url_shiny_hash_params
    ww = url_hash[:tyre_w]
    hh = url_hash[:tyre_h]
    rr = url_hash[:tyre_r]
    result = []
    10.times do |i|
      case i
      when 0
        result << "#{ww}#{hh}r#{rr}"
      when 1
        result << "#{ww} #{hh}r#{rr}"
      when 2
        result << "#{ww}/#{hh} р#{rr}"
      when 3
        result << "#{ww} #{hh} r#{rr}"
      when 4
        result << "#{ww}/#{hh} R#{rr}"
      when 5
        result << "#{ww} #{hh} R#{rr}"
      when 6
        result << "#{ww}x#{hh} R#{rr}"
      when 7
        result << "#{ww}/#{hh} на R#{rr}"
      when 8
        result << "#{ww}/#{hh} на #{rr}"
      else
        result << "#{ww} #{hh} #{rr}"
      end
    end

    result.shuffle
  end

  def replace_name_size(url_params)
    result = ''
    if size_present_in_url?
      ww = url_params[:tyre_w]
      hh = url_params[:tyre_h]
      rr = url_params[:tyre_r]

      case rand(1..10) % 10
      when 1
        result = "#{ww}/#{hh} на #{rr}"
      when 2
        result = "#{ww}/#{hh} р#{rr}"
      when 3
        result = "#{ww} #{hh} r#{rr}"
      when 4
        result = "#{ww}/#{hh} R#{rr}"
      when 5
        result = "#{ww} #{hh} R#{rr}"
      when 6
        result = "#{ww}x#{hh} R#{rr}"
      when 7
        result = "#{ww}/#{hh} на R#{rr}"
      when 8
        result = "#{ww} #{hh}r#{rr}"
      else
        result = "#{ww} #{hh} #{rr}"
      end
    end

    if size_only_diameter_in_url?
      result = ''
      case rand(1..12)
      when 1
        result = "р"
      when 3
        result = "p"
      when 5, 6, 7
        result = "r"
      else
        result = "R"
      end

      result = result + url_params[:tyre_r]
      result = result + " " + random_name_brand(url_params[:tyre_brand]) if url_params[:tyre_brand].present?
      puts "url_params[:tyre_r] = #{url_params[:tyre_r]}"
    end

    if size_only_brand_in_url?
      result = random_name_brand(url_params[:tyre_brand])
    end
    # result = "" if !(size_only_diameter_in_url?||size_only_brand_in_url?||size_present_in_url?)

    result

  end

  def replace_size_to_template(str)
    # search_size_1 = /\d{3}([ \/.-xXхХ]*| на )\d{2}([ \/.-xXхХ]*| на )(|[ rRpPрР])([ \/.-xXхХ]*)\d{2}([.,]\d{1})?[ \/.-]*[ cCсС]*/
    # search_size_2 = /(на |)[ rRpPрР]\d{2}([.,]\d{1})?[ \/.-xXхХ]*[ cCсС]*([ \/.-xXхХ]*| на )\d{3}([ \/.-xXхХ]*| на )\d{2}/
    search_size_1 = SEARCH_SIZE_1
    search_size_2  = SEARCH_SIZE_2

    return str if str.nil? # Убедитесь что str не nil

    if str.match?(search_size_1)
      str.gsub!(search_size_1, " [size] ")
    end
    if str.match?(search_size_2)
      str.gsub!(search_size_2, " [size] ")
    end
    # Замена ручных маркировок в json-файле ширины, высоты и диаметра на шаблон, для дальнейшей обработки
    ["111111", "222222", "333333"].each do |value|
      if str.include?(value)
        str.gsub!(value, " [w-] ") if value == "111111"
        str.gsub!(value, " [h-] ") if value == "222222"
        str.gsub!(value, " [r-] ") if value == "333333"
      end
    end
    replace_name_to_template(str)
    str
  end

  def replace_reverse_size_to_template(str)
    search_size_1 = '195/65R15'
    return str if str.nil? # Убедитесь что str не nil

    str.gsub!("[size]", search_size_1) unless str.nil?
    # str.gsub!(search_size_2, " [size] ")
    # Замена ручных маркировок в json-файле ширины, высоты и диаметра на шаблон, для дальнейшей обработки
    str.gsub!("[w-]", "111111") unless str.nil?
    str.gsub!("[h-]", "222222") unless str.nil?
    str.gsub!("[r-]", "333333") unless str.nil?

    str
  end

  def insert_brand_url(text)
    brands = Brand.all
    # Создать хэш с именами брендов в качестве ключей и URL в качестве значений
    brand_urls = brands.each_with_object({}) do |brand, hash|
      hash[brand.name] = "<a href='https://prokoleso.ua/shiny/#{brand.url}/'>#{brand.name}</a>"
    end

    # Проверить, есть ли названия брендов в тексте и заменить их на URL
    brand_urls.each do |brand, url|
      text.sub!(brand, url)
    end

  end

  def insert_season_url_new(text)
    url_shiny = url_shiny_hash_params
    diameter = url_shiny[:tyre_r]
    season = url_shiny[:tyre_season]
    type_season = {
      'летние': { value: "letnie",
                  season: 1,
                  state: { season_url: true,
                           season_size: true,
                           season_diameter: true
                  },
                  search_str: /((Л|л)етн(ие|яя|юю|их|ими)\s+(шин(ы|а|у|ами)|резин(а|ы|у|ой)))/,
      },
      'зимние': { value: 'zimnie',
                  season: 2,
                  state: { season_url: true,
                           season_size: true,
                           season_diameter: true
                  },
                  search_str: /((З|з)имн(ие|яя|юю|их|ими)\s+(шин(ы|а|у|ами)|резин(а|ы|у|ой)))/
      },
      'всесезонные': { value: 'vsesezonie',
                       season: 3,
                       state: { season_url: true,
                                season_size: true,
                                season_diameter: true
                       },
                       search_str: /((В|в)сесезонн(ые|ие|ая|юю|их|ими|ыми)\s+(шин(ы|а|у|ами)|резин(а|ы|у|ой)))/
      }

    }
    arr_size = arr_size_to_error

    # search_size = /\s+\d{3}([ \/.-xXхХ]*| на )\d{2}([ \/.-xXхХ]*| на )(|[ rRpPрР])([ \/.-xXхХ]*)\d{2}([.,]\d{1})?[ \/.-]*[ cCсС]*/
    # search_size_2 = /(на |)[ rRpPрР]\d{2}([.,]\d{1})?[ \/.-xXхХ]*[ cCсС]*([ \/.-xXхХ]*| на )\d{3}([ \/.-xXхХ]*| на )\d{2}/
    search_size = SEARCH_SIZE_1
    search_size_2  = SEARCH_SIZE_2


    replaced = {}
    text = text.each_line.map do |line|

      replaced = false
      type_season.each do |key, value|

        # if value[:season] != season
        part_url = value[:value] + '/'
        regex = value[:search_str]
        match = line.match(regex)
        if match && value[:state][:season_url]
          url = "<a href='https://prokoleso.ua/shiny/#{part_url}'>#{match[0]}</a>"
          line.sub!(regex, url)
          value[:state][:season_url] = false
          replaced = true
        end

        break if replaced
      end

      # ссылки на размеры
      type_season.each do |key, value|

        regex = /(#{value[:search_str]}\s*#{search_size})/
        match = line.match(regex)
        unless match
          regex = /(#{value[:search_str]}\s*#{search_size_2})/
          match = line.match(regex)
        end
        part_url_size = "w-#{url_shiny[:tyre_w]}/h-#{url_shiny[:tyre_h]}/r-#{url_shiny[:tyre_r]}/"
        part_url = value[:season].to_i == season.to_i ? '' : value[:value] + '/'
        if match && value[:state][:season_size]
          url = "<a href='https://prokoleso.ua/shiny/#{part_url}#{part_url_size}'>#{match[0]}</a>"
          line.sub!(regex, url)
          value[:state][:season_size] = false
          replaced = true
        end
        break if replaced
      end

      # ссылки на диаметры
      type_season.each do |key, value|
        regex = /\b((R|r)#{diameter})\b/
        match = line.match(regex)
        part_url_size = "r-#{url_shiny[:tyre_r]}/"
        part_url = value[:season].to_i == season.to_i ? '' : value[:value] + '/'
        txt_season = value[:season].to_i == season.to_i ? '' : key

        if match && value[:state][:season_size]
          url = "<a href='https://prokoleso.ua/shiny/#{part_url}#{part_url_size}'>#{txt_season} #{match[0]}</a>"
          line.sub!(regex, url)
          value[:state][:season_size] = false
          replaced = true
        end
        break if replaced
      end

      line
    end.join("")
    # ссылка на страницу оплата и доставка
    regex = /(оплат(а|ы)(| и доставк(а|и)))/
    match = text.match(regex)
    if match
      url = "<a href='https://prokoleso.ua/oplata-i-dostavka/'>#{match[0]}</a>"
      text.sub!(regex, url)
    end

    # ссылка на страницу контакты
    regex = /(проконсультироваться|консультаци(я|ю|и)|сотрудничеств(а|о)|ответить на все вопросы|профессионал(ы|ов)|(Н|н)аш(ей|а|у) команд(а|у|ой))/
    match = text.match(regex)
    if match
      url = "<a href='https://prokoleso.ua/about/'>#{match[0]}</a>"
      text.sub!(regex, url)
    end

    # вернуть измененный текст
    text
  end

  def replace_name_to_template(text)
    text.gsub!(/((U|u)kr(S|s)hina|UKRSHINA)(\.(com|COM)\.(UA|ua))|(У|у)кр(Ш|ш)ина|УКРШИНА|Ukrshina/, "ProKoleso")
    text.gsub!(/((I|i)nfo(S|s)hina|INFOSHINA)(\.(com|COM)\.(UA|ua))|(И|и)нфо(Ш|ш)ина|ИНФОШИНА|Infoshina/, "ProKoleso")
    text.gsub!(/((R|r)(ezina|EZINA)(\.(cc|CC|сс|СС)))/, "ProKoleso")
    text.gsub!(/((P|p)ro(K|k)oleso|PROKOLESO)\.(u|U)((a|A)|(а|А))/, "ProKoleso")

    sentences = text.split(/\.|\!/).map(&:strip)

    transformed_sentences = sentences.map do |sentence|
      case sentence
      when /(?:^|\.)\s*Потому\s*[\p{P}\p{S}]*\s*что\s*/, /(?:^|\.)\s*(Поэтому|А|Но)\s*/, /(?:^|\.)\s*Эт(и|о|от)\s*/
        # puts "sentence === #{sentence}"
        sentence.sub($&, '').gsub(/^[\p{P}\p{S}]+/, '').split.map.with_index { |word, i| i.zero? ? word.capitalize : word }.join(' ')
      when /\s*эт(и|о|от)\s*/
        # puts "sentence это === #{sentence}"
        sentence.gsub(/\s*эт(о|и|от)\s*/, '')
      else
        sentence
      end
    end

    transformed_text = transformed_sentences.join('. ')

    transformed_text
  end

  def txt_file_to_json
    file_path = Rails.root.join('lib', 'template_texts', 'data.txt')
    texts = {}
    current_text = {}
    current_key = ''
    index = 1

    File.foreach(file_path) do |line|
      line = line.strip
      replace_name_to_template(line)

      if line.include?(':')
        current_key, value = line.split(':').map(&:strip)
        if current_key == 'TextBody'
          current_text[current_key] = [value]
        else
          current_text[current_key] = value
        end
      elsif line.empty? && !current_text.empty?
        texts["Block_#{index}"] = current_text
        current_text = {}
        index += 1
      elsif !current_key.empty? && !line.empty?
        current_text[current_key] << line
      end

    end

    texts["Block_#{index}"] = current_text unless current_text.empty?
    file_path = Rails.root.join('lib', 'template_texts', 'data.json')

    File.open(file_path, 'w') do |f|
      f.write(JSON.pretty_generate(texts))
    end
  end

  def data_json_to_hash
    file_path = Rails.root.join('lib', 'template_texts', 'data.json')
    return unless File.exist?(file_path) # Return nil if the file doesn't exist

    begin
      file = File.read(file_path)
      data_hash = JSON.parse(file)
      # puts data_hash
    rescue Exception => e
      # Вывод информации об ошибке, если файл не может быть прочитан
      puts "Could not read file: #{e.message}"
      return nil # Return nil in case of an exception
    end
    data_hash
  end

  def arr_params_url
    result = []
    # url разбивается на массив значений
    url = params[:url]
    url_parts = ''
    if url.present?
      CGI::unescape(url)
      url_parts = url.split('/')
      # удаляем из массива ["https:","","prokoleso.ua","shiny","w-255","h-55","r-20","zimnie"] первые 4 элемента
      result = url_parts.drop(4)
    end

    result
  end

  def url_shiny_hash_params
    # Делаем хеш из параметров полученного url
    url_parts = arr_params_url
    url_hash = {
      tyre_w: '',
      tyre_h: '',
      tyre_r: '',
      tyre_season: 0,
      tyre_brand: '',
    }
    # if url_parts.include?('shiny') && url_parts != {}
    # &&
    # url_parts.any? { |part| part.match(/w-\d+/) } &&
    # url_parts.any? { |part| part.match(/h-\d+/) } &&
    # url_parts.any? { |part| part.match(/r-\d+/) }
    if url_parts != {}
      url_parts.each do |el|

        case el
        when /w-\d+/
          url_hash[:tyre_w] = el.to_s.gsub('w-', '')
        when /h-\d+/
          url_hash[:tyre_h] = el.to_s.gsub('h-', '')
        when /r-\d+/
          url_hash[:tyre_r] = el.to_s.gsub('r-', '')
        when 'letnie'
          url_hash[:tyre_season] = 1
        when 'zimnie'
          url_hash[:tyre_season] = 2
        when 'vsesezonie'
          url_hash[:tyre_season] = 3
        else
          url_hash[:tyre_brand] = el if Brand.exists?(url: el)

        end

      end
    end
    url_hash
  end

  def size_present_in_url?
    url_parts = url_shiny_hash_params
    ![url_parts[:tyre_w], url_parts[:tyre_h], url_parts[:tyre_r]].any?(&:empty?)
  end

  def size_only_diameter_in_url?
    url_parts = url_shiny_hash_params
    url_parts[:tyre_r].present? && [url_parts[:tyre_w], url_parts[:tyre_h]].any?(&:empty?)
  end

  def size_only_brand_in_url?
    url_parts = url_shiny_hash_params
    url_parts[:tyre_brand].present? && !size_present_in_url? && !size_only_diameter_in_url?
  end

  def type_for_url_shiny
    url_parts = url_shiny_hash_params
    # result = 0
    size = ![url_parts[:tyre_w], url_parts[:tyre_h], url_parts[:tyre_r]].any?(&:empty?) ? 100 : 0
    diameter = url_parts[:tyre_r].present? && [url_parts[:tyre_w], url_parts[:tyre_h]].any?(&:empty?) ? 200 : 0
    brand = url_parts[:tyre_brand].present? ? 10 : 0
    season = url_parts[:tyre_season]
    # puts "url_parts === #{url_parts.inspect}"
    # puts "size === #{size}"
    # puts "diameter === #{diameter}"
    # puts "brand === #{brand}"
    # puts "season === #{season}"
    result = size + diameter + season + brand
    result
  end

  def alphanumeric_chars_count_for_url_shiny
    # минимальное количество знаков в статье по урл без учета текста по сезонности
    result = 0
    puts "type_for_url_shiny = #{type_for_url_shiny}"
    case type_for_url_shiny

    when 100, 110
      # варианты по размеру
      # размер и размер+бренд
      result = 3500

    when  101, 102, 103, 111, 112, 113
      # варианты по размеру
      # размер+сезон и размер+бренд+сезон
      result = 2500

    when 200, 210
      # варианты по диаметру
      # диаметр и диаметр+бренд
      result = 1000
    when 201, 202, 203, 211, 212, 213
      # варианты по диаметру
      # диаметр+сезон и диаметр+бренд+сезон
      result = 500

    when 10
      # варианты по бренду
      result = 800

    when 11, 12, 13
      # варианты по бренду с сезоном
      result = 500
    else
      result = 0
    end

    result

  end

  def print_errors_text?
    url_param = url_shiny_hash_params
    case url_param[:tyre_r].to_i
    when  14, 15, 16, 17, 18, 19
      true
    else
      false
    end
  end

  def clear_size_in_sentence
    # Находим и зачищаем все записи, содержащие число 195, 65, 15 .
    posts195 = SeoContentTextSentence.where("sentence LIKE ?", "%195%")
    posts65 = SeoContentTextSentence.where("sentence LIKE ?", "%65%")
    posts15 = SeoContentTextSentence.where("sentence LIKE ?", "%15%")

    posts195.each do |post|
      updated_sentence = post.sentence.gsub('195', ' ')
      post.update(sentence: updated_sentence)
    end
    posts65.each do |post|
      updated_sentence = post.sentence.gsub('65', ' ')
      post.update(sentence: updated_sentence)
    end
    posts15.each do |post|
      updated_sentence = post.sentence.gsub('15', ' ')
      post.update(sentence: updated_sentence)
    end
  end

  # def clear_size_temp
  #   posts = SeoContentText.where("type_text LIKE ?", "%_1")
  #   posts.each do |post|
  #     updated_sentence = post.type_text.gsub('_1', ' ')
  #     post.update(type_text: updated_sentence)
  #   end
  # end

end