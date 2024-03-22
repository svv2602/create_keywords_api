# app/services/string_processing.rb
module StringProcessing
  def arr_size_name_min(ww, hh, rr, i)
    result = ''

    case i % 10
    when 1
      result = "#{ww} #{hh}r#{rr}"
    when 2
      result = "#{ww}/#{hh} P#{rr}"
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
        result << "#{ww}/#{hh} P#{rr}"
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
    ww = url_params[:tyre_w]
    hh = url_params[:tyre_h]
    rr = url_params[:tyre_r]

    case rand(1..10) % 10
    when 1
      result = "#{ww}/#{hh} на #{rr}"
    when 2
      result = "#{ww}/#{hh} P#{rr}"
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
    result
  end

  def replace_size_to_template(str)
    search_size_1 = /\d{3}([ \/.-xXхХ]*| на )\d{2}([ \/.-xXхХ]*| на )(|[ rRpPрР])([ \/.-xXхХ]*)\d{2}([.,]\d{1})?[ \/.-]*[ cCсС]*/
    search_size_2 = /(на |)[ rRpPрР]\d{2}([.,]\d{1})?[ \/.-xXхХ]*[ cCсС]*([ \/.-xXхХ]*| на )\d{3}([ \/.-xXхХ]*| на )\d{2}/

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
    season = url_shiny_hash_params[:tyre_season]
    type_season = {
      '1': { value: "letnie",
             season: 1,
             state: { season_url: true,
                      season_size: true },
             search_str: /((Л|л)етн(ие|яя|юю)\s+(шин(ы|а|у)|резин(а|ы|у)))/,
      },
      '2': { value: 'zimnie',
             season: 2,
             state: { season_url: true,
                      season_size: true },
             search_str: /((З|з)имн(ие|яя|юю)\s+(шин(ы|а|у)|резин(а|ы|у)))/
      },
      '3': { value: 'vsesezonie',
             season: 3,
             state: { season_url: true,
                      season_size: true },
             search_str: /((В|в)сесезонн(ые|ие|ая|юю)\s+(шин(ы|а|у)|резин(а|ы|у)))/
      }

    }
    arr_size = arr_size_to_error

    search_size = /\s+\d{3}([ \/.-xXхХ]*| на )\d{2}([ \/.-xXхХ]*| на )(|[ rRpPрР])([ \/.-xXхХ]*)\d{2}([.,]\d{1})?[ \/.-]*[ cCсС]*/
    search_size_2 = /(на |)[ rRpPрР]\d{2}([.,]\d{1})?[ \/.-xXхХ]*[ cCсС]*([ \/.-xXхХ]*| на )\d{3}([ \/.-xXхХ]*| на )\d{2}/

    replaced = {}
    text = text.each_line.map do |line|

      replaced = false
      type_season.each do |key, value|

        # if value[:season] != season
        part_url = value[:value] + '/'
        regex = value[:search_str]
        match = line.match(regex)

        if match && value[:state][:season_url]
          puts "match = = #{match}"
          url = "<a href='https://prokoleso.ua/shiny/#{part_url}'>#{match[0]}</a>"
          puts "url = = #{url}"
          puts line
          line.sub!(regex, url)
          puts line
          value[:state][:season_url] = false
          puts "value[:state][:season_url] = = #{value[:state][:season_url]}"
          replaced = true
        end

        break if replaced
      end

      # ссылки на размеры
      type_season.each do |key, value|
        url_shiny_hash_params[:tyre_w]

        regex = /(#{value[:search_str]}\s*#{search_size})/
        match = line.match(regex)
        part_url_size = "w-#{url_shiny_hash_params[:tyre_w]}/h-#{url_shiny_hash_params[:tyre_h]}/r-#{url_shiny_hash_params[:tyre_r]}/"

        puts "value[:season].to_i = #{value[:season].to_i} ? season.to_i = #{season.to_i}"
        part_url = value[:season].to_i == season.to_i ? '' : value[:value] + '/'
        if match && value[:state][:season_size]
          url = "<a href='https://prokoleso.ua/shiny/#{part_url}#{part_url_size}'>#{match[1]}</a>"
          line.sub!(regex, url)
          value[:state][:season_size] = false
          replaced = true
        end
        break if replaced
      end
      line
    end.join("")

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
        puts "sentence это === #{sentence}"
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
    # url разбивается на массив значений
    url = params[:url]
    url_parts = ''
    if url.present?
      CGI::unescape(url)
      url_parts = url.split('/')
    end
    url_parts
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
    if url_parts.include?('shiny') && url_parts != '' &&
      url_parts.any? { |part| part.match(/w-\d+/) } &&
      url_parts.any? { |part| part.match(/h-\d+/) } &&
      url_parts.any? { |part| part.match(/r-\d+/) }

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

  def print_errors_text?
    url_param = url_shiny_hash_params
    case url_param[:tyre_r].to_i
    when 13, 14, 15, 16, 17, 18, 19, 20
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






end