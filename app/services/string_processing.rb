# app/services/string_processing.rb
module StringProcessing
  def arr_size_name_min(ww, hh, rr, i)
    result = ''

    case i % 5
    when 1
      result = "#{ww} #{hh}r#{rr}"
    when 2
      result = "#{ww}/#{hh} P#{rr}"
    when 3
      result = "#{ww}#{hh} r#{rr}"
    when 4
      result = "#{ww}/#{hh} R#{rr}"
    else
      result = "#{ww} #{hh} #{rr}"
    end
    result
  end

  def replace_size_to_template(str)
    search_size_1 = /\d{3}([ \/.-xXхХ]*| на )\d{2}([ \/.-xXхХ]*| на )(|[ rRpPрР])([ \/.-xXхХ]*)\d{2}([.,]\d{1})?[ \/.-]*[ cCсС]*/
    search_size_2 = /(на |)[ rRpPрР]\d{2}([.,]\d{1})?[ \/.-xXхХ]*[ cCсС]*([ \/.-xXхХ]*| на )\d{3}([ \/.-xXхХ]*| на )\d{2}/
    str.gsub!(search_size_1, " [size] ")
    str.gsub!(search_size_2, " [size] ")
    # Замена ручных маркировок в json-файле ширины, высоты и диаметра на шаблон, для дальнейшей обработки
    str.gsub!("111111", " [w-] ")
    str.gsub!("222222", " [h-] ")
    str.gsub!("333333", " [r-] ")
    replace_name_to_template(str)
    str
  end

  def replace_name_to_template(text)
    text.gsub!(/((U|u)kr(S|s)hina|UKRSHINA)(\.(com|COM)\.(UA|ua))|(У|у)кр(Ш|ш)ина|УКРШИНА|Ukrshina/, "ProKoleso")

    sentences = text.split(/\.|\!/).map(&:strip)

    transformed_sentences = sentences.map do |sentence|
      case sentence
      when /(?:^|\.)\s*Потому\s*[\p{P}\p{S}]*\s*что\s*/, /(?:^|\.)\s*(Поэтому|А|Но)\s*/,  /(?:^|\.)\s*Эт(и|о|от)\s*/
        puts "sentence === #{sentence}"
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
      return nil  # Return nil in case of an exception
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

end