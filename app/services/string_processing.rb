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

  def arr_size_diski_to_error
    url_hash = url_shiny_hash_params
    ww = url_hash[:tyre_w]
    pcd = url_hash[:disk_pcd]
    rr = url_hash[:tyre_r]
    result = []
    10.times do |i|
      case i
      when 0
        result << "#{ww}#{rr}r#{pcd}"
      when 1
        result << "#{pcd} #{ww}r#{rr}"
      when 2
        result << "#{ww}/#{rr}R#{pcd}"
      when 3
        result << "#{ww}\" #{rr} дюймов #{pcd}"
      when 4
        result << "#{ww}J#{rr} R#{pcd}"
      when 5
        result << "#{rr}x#{ww} #{pcd}"
      when 6
        result << "PCD#{pcd} на R#{rr}W#{ww}"
      when 7
        result << "R#{rr}J#{ww} на #{pcd}"
      when 8
        result << "R#{rr} PCD#{pcd} J#{ww}"
      else
        result << "#{ww} на #{rr} дюймов"
      end
    end

    result.shuffle
  end

  def replace_name_size(url_params)
    result = ''
    if size_present_in_url? && url_type_by_parameters != 1
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
      result = result + " " + random_name_brand(url_params[:tyre_brand]) if url_params[:tyre_brand].present?
    end

    if size_present_in_url? && url_type_by_parameters == 1
      ww = url_params[:tyre_w]
      pcd = url_params[:disk_pcd]
      rr = url_params[:tyre_r]

      case rand(1..10) % 10
      when 2
        result << "#{ww}J#{rr}R#{pcd}"
      when 3
        result << "#{ww}J #{rr} дюймов pcd#{pcd}"
      when 4
        result << "J#{ww}R#{rr} PCD#{pcd}"
      when 6
        result << "#{pcd} на #{rr}x#{ww}"
      when 8
        result << "R#{rr}/W#{ww}/PCD#{pcd}"
      else
        result << "R#{rr} W#{ww} PCD#{pcd}"
      end
      result = result + " " + random_name_brand(url_params[:tyre_brand]) if url_params[:tyre_brand].present?
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
    search_size_2 = SEARCH_SIZE_2
    search_size_3 = SEARCH_SIZE_3

    return str if str.nil? # Убедитесь что str не nil

    if str.match?(search_size_1)
      str.gsub!(search_size_1, " [size] ")
    end
    if str.match?(search_size_2)
      str.gsub!(search_size_2, " [size] ")
    end
    if str.match?(search_size_3)
      str.gsub!(search_size_3, " [size] ")
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
    str_site = "<a href='https://prokoleso.ua/"
    str_site_ua = url_type_ua? ? "ua/" : ""

    case url_type_by_parameters
    when 0
      str_site_type = "shiny/"
    when 1
      str_site_type = "diski/"
    when 2
      str_site_type = "gruzovye-shiny/"
    else
      str_site_type = ''
    end
    str_base = str_site + str_site_ua + str_site_type
    # Создать хэш с именами брендов в качестве ключей и URL в качестве значений
    brand_urls = brands.each_with_object({}) do |brand, hash|
      if brand.name.match(/\A[a-zA-Z\s]*\Z/)
        hash[brand.name] = "#{str_base}#{brand.url}/'>#{brand.name}</a>"
      end
    end

    # Проверить, есть ли названия брендов в тексте и заменить их на URL
    brand_urls.each do |brand, url|
      text.sub!(brand, url)
    end

  end

  def type_season_or_axis
    type_season = {
      'летние': { value: "letnie",
                  season: 1,
                  state: { season_url: true,
                           season_size: true,
                           season_diameter: true
                  },
                  search_str: /((Л|л)етн(ие|яя|юю|их|ими)\s+((шин(ы|ами|ах|у|а))|(резин(а|ы|у|ой))))/,
                  search_str_ua: /((Л|л)ітн(і|я|ю|іх|іми)\s+((шин(и|ами|ах|у|а))|(резин(а|и|у|ою))))/,
      },
      'зимние': { value: 'zimnie',
                  season: 2,
                  state: { season_url: true,
                           season_size: true,
                           season_diameter: true
                  },
                  search_str: /((З|з)имн(ие|яя|юю|их|ими)\s+((шин(ы|ами|ах|у|а))|(резин(а|ы|у|ой))))/,
                  search_str_ua: /((З|з)им(ов|н)(у|а|і|я|ю|их|ими|іх|іми)\s+((шин(и|ами|ах|у|а))|(резин(а|и|у|ою))))/
      },
      'всесезонные': { value: 'vsesezonie',
                       season: 3,
                       state: { season_url: true,
                                season_size: true,
                                season_diameter: true
                       },
                       search_str: /((В|в)сесезонн(ые|ие|ая|юю|их|ими|ыми)\s+((шин(ы|ами|ах|у|а))|(резин(а|ы|у|ой))))/,
                       search_str_ua: /((В|в)сесезонн(і|я|ю|их|ими|іх|іми)\s+((шин(и|ами|ах|у|а))|(резин(а|и|у|ою))))/
      }

    }
    type_axis = {
      'прицепные': { value: "axis-pritsepnaya",
                     season: 1,
                     state: { season_url: true,
                              season_size: true,
                              season_diameter: true
                     },
                     search_str: /((П|п)рицепн(ые|ая|ую|ых|ыми)\s+((шин(ы|ами|ах|у|а))|(резин(а|ы|у|ой))))/,
                     search_str_ua: /((П|п)р(и|е)(ц|ч)(і|е)пн(і|я|ю|іх|іми)\s+((шин(и|ами|ах|у|а))|(резин(а|и|у|ою))))/,
      },
      'рулевые': { value: 'axis-rulevaya',
                   season: 2,
                   state: { season_url: true,
                            season_size: true,
                            season_diameter: true
                   },
                   search_str: /((Р|р)улев(ые|ая|ую|ых|ыми)\s+((шин(ы|ами|ах|у|а))|(резин(а|ы|у|ой))))/,
                   search_str_ua: /((З|з)им(ов|н)(у|а|і|я|ю|их|ими|іх|іми)\s+((шин(и|ами|ах|у|а))|(резин(а|и|у|ою))))/
      },
      'ведущие': { value: 'axis-vedushchaya',
                   season: 3,
                   state: { season_url: true,
                            season_size: true,
                            season_diameter: true
                   },
                   search_str: /((В|в)едущ(ие|ая|юю|их|ими|ыми)\s+((шин(ы|ами|ах|у|а))|(резин(а|ы|у|ой))))/,
                   search_str_ua: /((В|в)едуч(і|я|ю|их|ими|іх|іми)\s+((шин(и|ами|ах|у|а))|(резин(а|и|у|ою))))/
      }

    }

    type_diski = {
      'легкосплавные': { value: "type-legkosplavnyye",
                     season: 1,
                     state: { season_url: true,
                              season_size: true,
                              season_diameter: true
                     },
                     search_str: /((Л|л)(ит|егкославн)(ые|ых|ыми)\s+(диск(и|ами|ах)))/,
                     search_str_ua: /((Л|л)(ит|егкославн)(і|их|ими|іх|іми)\s+(диск(и|ами|ах)))/,
      },
      'стальные': { value: 'type-stalnyye',
                   season: 2,
                   state: { season_url: true,
                            season_size: true,
                            season_diameter: true
                   },
                   search_str: /((С|с)(тальн)(ые|ых|ыми)\s+(диск(и|ами|ах)))/,
                   search_str_ua: /((С|с)(тальн)(і|их|ими|іх|іми)\s+(диск(и|ами|ах)))/
      }

    }

    result = case url_type_by_parameters
             when 0
               type_season
             when 1
               type_diski
             when 2
               type_axis
             end
    result

  end

  def str_url_type_pharagraph
    result = case url_type_by_parameters
             when 0
               "shiny"
             when 1
               "diski"
             when 2
               "gruzovye-shiny"
             end
    result
  end

  def insert_season_url_new(text)
    url_shiny = url_shiny_hash_params
    diameter = url_shiny[:tyre_r]
    season = url_shiny[:tyre_season]
    season = url_shiny[:tyre_axis] if url_type_by_parameters == 2
    tires_size = "#{url_shiny[:tyre_w]}/#{url_shiny[:tyre_h]}R#{url_shiny[:tyre_r]}"

    type_season = type_season_or_axis
    unless AXIS_PRICEP.include?(tires_size)
      type_season[:'прицепные'][:state][:season_size] = false if url_type_by_parameters == 2
    end
    unless ["17.5", "19.5", "22.5"].include?(diameter)
      type_season[:'прицепные'][:state][:season_diameter] = false if url_type_by_parameters == 2
    end

    arr_size = arr_size_to_error

    search_size = SEARCH_SIZE_1
    search_size_2 = SEARCH_SIZE_2
    search_size_3 = SEARCH_SIZE_3

    str_url = url_type_ua? ? "<a href='https://prokoleso.ua/ua/#{str_url_type_pharagraph}" : "<a href='https://prokoleso.ua/#{str_url_type_pharagraph}"
    replaced = {}
    i = 0
    text = text.each_line.map do |line|
      i += 1
      if line.include?("<a href=") || line.include?("h2") || line.include?("h3")
        line
      else
        replaced = false
        type_season.each do |key, value|
          break if replaced
          # if value[:season] != season
          part_url = value[:value] + '/'

          regex_season = url_type_ua? ? value[:search_str_ua] : value[:search_str]
          match = line.match(regex_season)

          if match && value[:state][:season_url]
            puts "match ======== #{match.inspect}"
            url = "#{str_url}/#{part_url}'>#{match[0]}</a>"
            line.sub!(regex_season, url)
            value[:state][:season_url] = false
            replaced = true
          end

        end

        # ссылки на размеры

        type_season.each do |key, value|
          break if replaced
          break if [url_shiny[:tyre_w], url_shiny[:tyre_h], url_shiny[:tyre_r]].any? { |element| element.to_s.empty? }
          # regex = /(#{value[:search_str]}\s*#{search_size})/
          regex_season = url_type_ua? ? value[:search_str_ua] : value[:search_str]
          regex = Regexp.new("(#{Regexp.union(regex_season, search_size, search_size_2)}\s*)")

          match = line.match(regex)

          part_url_size = "w-#{url_shiny[:tyre_w]}/h-#{url_shiny[:tyre_h]}/r-#{url_shiny[:tyre_r]}/"
          part_url = value[:season].to_i == season.to_i ? '' : value[:value] + '/'
          if match && value[:state][:season_size]
            puts "tires_size ===== #{tires_size}"
            url = "#{str_url}/#{part_url}#{part_url_size}'>#{match[0]}</a>"
            line.sub!(regex, url)
            value[:state][:season_size] = false
            replaced = true
          end

        end

        # ссылки на диаметры
        type_season.each do |key, value|
          break if replaced
          regex = /\b((R|r)#{diameter})\b/
          match = line.match(regex)
          part_url_size = "r-#{url_shiny[:tyre_r]}/"
          part_url = value[:season].to_i == season.to_i ? '' : value[:value] + '/'

          if url_type_ua?
            if url_type_by_parameters == 0
              case value[:season].to_i
              when 1
                txt_season = 'літні'
              when 2
                txt_season = 'зимові'
              when 3
                txt_season = 'всесезонні'
              else
                txt_season = ''
              end
            end
            if url_type_by_parameters == 2
              case value[:season].to_i
              when 1
                txt_season = 'причіпні'
              when 2
                txt_season = 'рульові'
              when 3
                txt_season = 'ведучі'
              else
                txt_season = ''
              end
            end

          else
            txt_season = value[:season].to_i == season.to_i ? '' : key
          end

          if match && value[:state][:season_diameter]
            url = "#{str_url}/#{part_url}#{part_url_size}'>#{txt_season} #{match[0]}</a>"
            line.sub!(regex, url)
            value[:state][:season_diameter] = false
            replaced = true
          end
          # break if replaced
        end

        line

      end

    end.join("")

    # ссылка на страницу оплата и доставка
    regex = /(оплат(а|ы|и)(| и доставк(а|и)))/
    match = text.match(regex)
    if match
      url_ua = url_type_ua? ? "/ua" : ""
      url = "<a href='https://prokoleso.ua#{url_ua}/oplata-i-dostavka/'>#{match[0]}</a>"
      text.sub!(regex, url)
    end

    # ссылка на страницу контакты
    regex = /(проконсуль(тувати|тировать)(|ся)|консультац(и|і)(я|ю|и)|сотрудничеств(а|о)|співробітництв(а|о)|ответить на все вопросы|відповісти на всі запитання|профес(|с)(і|и)онал(и|ы|(і|о)в)|(Н|н)аш(ей|а|у) команд(а|у|ой))/
    match = text.match(regex)
    if match
      url_ua = url_type_ua? ? "/ua" : ""
      url = "<a href='https://prokoleso.ua#{url_ua}/about/'>#{match[0]}</a>"
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

  def txt_file_to_json(filename)
    file_path = Rails.root.join('lib', 'template_texts', "#{filename}.txt")
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
    file_path = Rails.root.join('lib', 'template_texts', "#{filename}.json")

    File.open(file_path, 'w') do |f|
      f.write(JSON.pretty_generate(texts))
    end
  end

  def data_json_to_hash(filename)
    file_path = Rails.root.join('lib', 'template_texts', "#{filename}.json")
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
      url = CGI::unescape(url)
      url_parts = url.split('/')
      # удаляем из массива ["https:","","prokoleso.ua","shiny","w-255","h-55","r-20","zimnie"] первые 4 элемента
      url_parts.delete("prokoleso.ua")
      url_parts.delete("https:")
      url_parts.delete("")
      result = url_parts
    end

    result
  end

  def url_type_by_parameters
    url_parts = arr_params_url
    # puts "url_parts! ========= #{url_parts.inspect} "
    case
    when url_parts.include?("diski")
      1
    when url_parts.include?("gruzovye-shiny")
      2
    else
      0
    end
  end

  def url_type_ua?
    url_parts = arr_params_url
    url_parts.any? { |part| part == "ua" }
  end

  def url_shiny_hash_params
    # Делаем хеш из параметров полученного url
    url_parts = arr_params_url
    url_hash = {
      tyre_w: '',
      tyre_h: '',
      tyre_r: '',
      tyre_season: 0,
      tyre_axis: 0,
      tyre_brand: '',
      disk_type: 0,
      disk_pcd: '',
      disk_et: '',
      disk_dia: ''
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
        when 'axis-pritsepnaya'
          url_hash[:tyre_axis] = 1
        when 'axis-rulevaya'
          url_hash[:tyre_axis] = 2
        when 'axis-vedushchaya'
          url_hash[:tyre_axis] = 3
        when 'type-legkosplavnyye'
          url_hash[:tyre_disk] = 1
        when 'type-stalnyye'
          url_hash[:disk_type] = 2
        when /pcd-\d+/
          url_hash[:disk_pcd] = el.to_s.gsub('pcd-', '')
        when /et-\d+/
          url_hash[:disk_et] = el.to_s.gsub('et-', '')
        when /dia-\d+/
          url_hash[:disk_dia] = el.to_s.gsub('dia-', '')
        else
          url_hash[:tyre_brand] = el if Brand.exists?(url: el)

        end

      end
    end
    url_hash
  end

  def size_present_in_popular?
    url_parts = url_shiny_hash_params
    size = url_parts[:tyre_w] + "/" + url_parts[:tyre_h] + " R" + url_parts[:tyre_r]
    key = url_parts[:tyre_r].to_sym
    TIRE_POPULAR_SIZES.key?(key) &&
      TIRE_POPULAR_SIZES[key].include?(size) &&
      [100, 110, 101, 102, 103].include?(type_for_url_shiny) # если есть размер или размер +бренд или размер+сезон
  end

  def size_present_in_url?
    url_parts = url_shiny_hash_params
    type_h_pcd = url_type_by_parameters == 1 ? url_parts[:disk_pcd] : url_parts[:tyre_h]
    ![url_parts[:tyre_w], type_h_pcd, url_parts[:tyre_r]].any?(&:empty?)
    # ![url_parts[:tyre_w], url_parts[:tyre_h], url_parts[:tyre_r]].any?(&:empty?)
  end

  def size_only_diameter_in_url?
    url_parts = url_shiny_hash_params
    type_h_pcd = url_type_by_parameters == 1 ? url_parts[:disk_pcd] : url_parts[:tyre_h]
    url_parts[:tyre_r].present? && [url_parts[:tyre_w], type_h_pcd].any?(&:empty?)
    # url_parts[:tyre_r].present? && [url_parts[:tyre_w], url_parts[:tyre_h]].any?(&:empty?)
  end

  def size_only_brand_in_url?
    url_parts = url_shiny_hash_params
    url_parts[:tyre_brand].present? && !size_present_in_url? && !size_only_diameter_in_url?
  end

  def type_for_url_shiny
    url_parts = url_shiny_hash_params

    type_h_pcd = url_type_by_parameters == 1 ? url_parts[:disk_pcd] : url_parts[:tyre_h]
    # распределение по разрядам суммы
    size = ![url_parts[:tyre_w], type_h_pcd, url_parts[:tyre_r]].any?(&:empty?) ? 100 : 0 # сотни
    # size = ![url_parts[:tyre_w], url_parts[:tyre_h], url_parts[:tyre_r]].any?(&:empty?) ? 100 : 0 # сотни - были
    diameter = url_parts[:tyre_r].present? && [url_parts[:tyre_w], url_parts[:tyre_h]].any?(&:empty?) ? 200 : 0 # сотни
    brand = url_parts[:tyre_brand].present? ? 10 : 0 # десятки

    season = case url_type_by_parameters
             when 0
               url_parts[:tyre_season] # единицы по сезону
             when 1
               url_parts[:disk_type] # единицы по типу диска
             when 2
               url_parts[:tyre_axis] # единицы по типу оси
             else
               0
             end

    result = size + diameter + brand + season
    result
  end

  def alphanumeric_chars_count_for_url_shiny
    # минимальное количество знаков в статье по урл без учета текста по сезонности
    result = 0
    # puts "type_for_url_shiny = #{type_for_url_shiny}"
    case type_for_url_shiny

    when 100, 110
      # варианты по размеру
      # размер и размер+бренд
      result = 4000

    when 101, 102, 103
      # варианты по размеру
      # размер+сезон
      result = 3000

    when 111, 112, 113
      # варианты по размеру
      # размер+бренд+сезон
      result = 2000

      #====================================================
    when 200, 210
      # варианты по диаметру
      # диаметр и диаметр+бренд
      result = 3000
    when 201, 202, 203
      # варианты по диаметру - диаметр+сезон
      result = 2000
    when 211, 212, 213
      # варианты по диаметру - диаметр+бренд+сезон
      result = 2000

      #====================================================
    when 10
      # варианты по бренду
      result = 2000

    when 11, 12, 13
      # варианты по бренду с сезоном
      result = 1500

    else
      result = 0
    end

    result

  end

  def alphanumeric_chars_count_for_url_gruzovye_shiny
    # минимальное количество знаков в статье по урл без учета текста по сезонности
    result = 0
    case type_for_url_shiny

    when 100, 110, 200, 210
      # варианты по размеру
      # размер и размер+бренд, диаметр+бренд
      result = 2000

    when 101, 102, 103, 201, 202, 203
      # варианты по диаметру - диаметр+ось
      # варианты по размеру - размер+ось
      result = 1500

    when 111, 112, 113, 211, 212, 213
      # варианты по диаметру - диаметр+бренд+ось
      # варианты по размеру - размер+бренд+ось
      result = 800

    when 10, 11, 12, 13
      # варианты по бренду и бренду с осью
      result = 800

    else
      result = 0
    end

    result

  end

  def alphanumeric_chars_count_for_url_diski
    # минимальное количество знаков в статье по урл без учета текста по сезонности
    result = 0
    case type_for_url_shiny

    when 100, 110, 200, 210
      # варианты по размеру
      # размер и размер+бренд, диаметр+бренд
      result = 2000

    when 101, 102, 103, 201, 202, 203
      # варианты по диаметру - диаметр+ось
      # варианты по размеру - размер+ось
      result = 1200

    when 111, 112, 113, 211, 212, 213
      # варианты по диаметру - диаметр+бренд+тип диска
      # варианты по размеру - размер+бренд+тип диска
      result = 1000

    when 10, 11, 12, 13
      # варианты по бренду и бренду с типом диска
      result = 1000

    else
      result = 0
    end

    result

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

  # задает количество вариантов написания для каждого абзаца исходного текста
  def seo_phrase(element_array, number_of_repeats, ind, str_snt)
    str_snt == 1 ? topics = seo_phrase_str(element_array, number_of_repeats, ind) : topics = seo_phrase_sentence(element_array, number_of_repeats, ind)

    new_text = ContentWriter.new.write_seo_text(topics, 3500) #['choices'][0]['message']['content'].strip

    if new_text
      begin
        new_text = new_text['choices'][0]['message']['content'].strip
      rescue => e
        puts "Произошла ошибка: #{e.message}"
      end
    end

    new_text
  end

  def seo_phrase_sentence(element_array, number_of_repeats, ind)
    # задание на рерайт по предложениям
    # ind - номер строки в текте, если 0 - то заголовок
    topics = ''
    topics += element_array.to_s
    if ind > 0
      topics += "\n Сделай #{number_of_repeats} вариантов этого предложения. "
      topics += "\n Каждый вариант должен состоять из одного предложения. "
      topics += "\n Постарайся сохранить количество ключевых слов, при этом тошнотность текста должна быть не больше 20%,"
      topics += "\n а водность текста должна быть не больше 60%"
      topics += "\n Если в предложении используются названия торговых брендов, то их из текста не убирать."
      topics += "\n "
      topics += "\n Избегай построения предложения как рекламный слоган или рекламный заголовок, "
      topics += "\n а также предложений в которых только один главный член предложения (подлежащее или сказуемое)"
      topics += "\n Пример - "
      topics += "\n Неправильно: ProKoleso: Доступные цены на шины - гарантия качества!"
      topics += "\n Правильно: 'ProKoleso предоставляет доступные цены на шины с гарантией качества.' "
      topics += "\n "
      topics += "\n Не использовать личные местоимения в единственном числе "
      topics += "\n Пример - "
      topics += "\n Неправильно: 'Я оформлю вам заказ на доставку.'"
      topics += "\n Правильно: 'Мы оформим вам заказ на доставку'"
      topics += "\n "
      topics += "\n Старайтесь избегать употребления местоимений, таких как 'их', 'них', 'его', 'ее' и так далее "
      topics += "\n Пример - "
      topics += "\n Неправильно: 'Yokohama - компания, которая славится технологиями. Их продукция пользуется популярностью.'"
      topics += "\n Правильно: 'Yokohama славится технологиями. Продукция компании пользуется популярностью.' "
      topics += "\n "

    else
      topics += "\n Сделай из этого текста #{number_of_repeats} вариантов эффектиного заголовка для статьи. "
      topics += "\n Заголовок должен состоять из одного предложения. "
    end

    topics
  end

  def seo_phrase_str(element_array, number_of_repeats, ind)
    # ind - номер строки в текте, если 0 - то заголовок
    topics = ''
    topics += element_array.to_s
    if ind > 0
      topics += "\n На тему, заданную в образце, Сделай #{number_of_repeats} вариантов текстов. "
      topics += "\n Количество  предложений в каждом варианте нужно сделать таким же, как в образце. "
      topics += "\n Количество печатных символов в ответе может быть больше, чем количество знаков в образце."
      topics += "\n Постарайся сохранить количество ключевых слов, при этом тошнотность текста должна быть не больше 20%,"
      topics += "\n а водность текста должна быть не больше 60%"
      topics += "\n Каждый вариант ответа должен состоять из одного абзаца (не использовать символ переноса каретки)"
      topics += "\n Предложения в абзаце должны быть самостоятельными по смыслу, т.е. не ссылаться на предыдущие предлжожения"
      topics += "\n Пример 1. "
      topics += "\n Неправильно: 'Шины различаются по типу. Каждый из этих типов шин имеет особенности'. "
      topics += "\n Правильно: 'Шины различаются по типу. Каждый тип шин имеет особенности'. "
      topics += "\n Пример 2. "
      topics += "\n Неправильно: 'Когда выбираете резину, не доверяйте низким ценам. Подобные предложения могут быть обманом'. "
      topics += "\n Правильно: 'Когда выбираете резину, не доверяйте низким ценам, подобные предложения могут быть обманом'. "
      topics += "\n Пример 3. "
      topics += "\n Неправильно: 'ProKoleso - надежный партнер для всех, кто ценит качество. Поэтому мы предлагаем лучшее'. "
      topics += "\n Правильно: 'ProKoleso - надежный партнер для всех, кто ценит качество. Мы предлагаем лучшее'. "
      topics += "\n Пример 4. "
      topics += "\n Неправильно: 'Не попадайтесь на предложение шин по недорогой цене. Чаще всего такие предложения обманчивы'. "
      topics += "\n Правильно: 'Не попадайтесь на предложение шин по недорогой цене. Дешевые предложения обманчивы'. "
      topics += "\n Пример 5. "
      topics += "\n Неправильно: 'Приобретение новых шин - залог безопасности. Поэтому выбирать нужно проверенных поставщиков'. "
      topics += "\n Правильно: 'Приобретение новых шин - залог безопасности. При покупке шин выбирать нужно проверенных поставщиков'. "
      topics += "\n Старайтесь избегать употребления местоимений, таких как 'их', 'них', 'его', 'ее' и так далее "
      topics += "\n Пример 6."
      topics += "\n Неправильно: 'Yokohama - компания, которая славится технологиями. Их продукция пользуется популярностью.'"
      topics += "\n Правильно: 'Yokohama славится технологиями. Продукция компании пользуется популярностью.' "
      topics += "\n "
      # topics += "\n  "
    else
      topics += "\n Сделай из этого текста #{number_of_repeats} вариантов эффектиного заголовка для статьи. "
      topics += "\n Заголовок должен состоять из одного предложения. "
    end

    topics
  end

  def make_array_phrase(var_phrase, i)
    txt = var_phrase.gsub("\n\n", "\n")
    txt = txt.gsub(/\*|\#/, "")
    txt = txt.gsub(/^("|)((\d+|)(|\s+))(В|в)ариант((|\s+)(|\d+(\s+|))(\.|\:|\-))/, "")
    txt = txt.split("\n")
    txt
  end

  def arr_to_table(arr, data_table_hash, select_number_table)
    5.times do |n|
      begin
        arr_record_to_table(arr, data_table_hash, select_number_table)
        break
      rescue => e
        puts "Attempt #{n + 1} failed with error: #{e.message}"
        raise if n == 4
        sleep(2 ** (n + 1)) # exponential backoff
      end
    end
  end

  def arr_record_to_table(arr, data_table_hash, select_number_table)
    previous_el = ''
    i = 0
    arr.each do |el|
      str = el.sub(/^\d+(\.|\))\s/, '')
      str = str.gsub(/^('|")|('|")$/, '')
      replace_size_to_template(str)

      # проверка на корректность ответов AI, если все ок, то записываем в таблицы

      case select_number_table
      when 1
        SeoContentText.create(str: str,
                              order_out: data_table_hash[:order_out],
                              type_tag: data_table_hash[:type_tag],
                              type_text: data_table_hash[:type_text],
                              content_type: data_table_hash[:content_type],
                              str_number: data_table_hash[:str_number]
        ) if el.present? && el.length > 20
      when 2
        SeoContentTextSentence.create(str_seo_text: data_table_hash[:str_seo_text],
                                      str_number: data_table_hash[:str_number],
                                      sentence: str,
                                      num_snt_in_str: data_table_hash[:num_snt_in_str],
                                      id_text: data_table_hash[:id_text],
                                      type_text: data_table_hash[:type_text],
                                      check_title: data_table_hash[:check_title]

        ) if el.present? && el.length > 20
      end

    end
  end

  def replace_size_tyre(array_of_string, url_params)
    arr = []
    size_count = array_of_string.count { |string| string.include?("[size]") }
    size_count.times do |i|
      arr << arr_size_name_min(url_params[:tyre_w], url_params[:tyre_h], url_params[:tyre_r], i)
    end
    arr
  end

  def replace_params_w_h_r_tyre(str, url_params)
    str = str.gsub('[r-]', url_params[:tyre_r])
    str = str.gsub('[h-]', url_params[:tyre_h])
    str = str.gsub('[w-]', url_params[:tyre_w])
    str
  end

end