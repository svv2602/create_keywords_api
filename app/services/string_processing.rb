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
    str
  end

  def replace_name_to_template(str)
    str.gsub!(/((U|u)kr(S|s)hina|UKRSHINA)(\.(com|COM)\.(UA|ua))|(У|у)кр(Ш|ш)ина|УКРШИНА|Ukrshina/, "ProKoleso")

    str
  end

  def template_txt_to_array_and_write_to_json(name_file_out)
    text_array = []
    file_path = Rails.root.join('lib', 'template_texts', 'text')
    file_path_out = Rails.root.join('lib', 'template_texts', name_file_out)

    begin
      File.foreach("#{file_path}.txt") do |line|
        text_array << replace_name_to_template(line.chomp)
      end
    rescue Errno::ENOENT
      puts "File not found"
      return
    end

    # Запись в файл
    File.write("#{file_path_out}.json", JSON.dump(text_array))
  end

  def read_array_from_json_file(name_file_out)
    file_path_out = Rails.root.join('lib', 'template_texts/finished_texts', name_file_out)
    begin
      json_string = File.read("#{file_path_out}.json")
    rescue Errno::ENOENT
      puts "File not found"
      raise "File not found"
    end

    array_from_json = JSON.parse(json_string)
    array_from_json
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