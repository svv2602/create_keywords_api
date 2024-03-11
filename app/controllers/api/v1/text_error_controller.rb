class Api::V1::TextErrorController < ApplicationController
  def text_line
    # test_url = 'https://prokoleso.ua/shiny/letnie/taurus/w-175/h-70/r-13/'
    # url = CGI::unescape(test_url) # возвращает URL обратно в незакодированном виде
    # GET /text_line?url=https%3A%2F%2Fprokoleso.ua%2Fshiny%2Fw-175%2Fh-70%2Fr-13%2F
    # url = CGI::unescape(params[:url]) # возвращает URL обратно в незакодированном виде

    result = arr_url_result_str(arr_url)

    render json: { result: result }
    puts result
  end

  def encoded_url(url)
    CGI::escape(url)
    # encoded_url = CGI::escape('https://prokoleso.ua/shiny/w-175/h-70/r-13/')
    # => "https%3A%2F%2Fprokoleso.ua%2Fshiny%2Fw-175%2Fh-70%2Fr-13%2F"
  end

  def arr_url
    url = params[:url]
    url_parts = ''
    if url.present?
      CGI::unescape(url)
      url_parts = url.split('/')
    end
    url_parts
  end

  def arr_url_result_str(url_parts)
    tyre_w = ''
    tyre_h = ''
    tyre_r = ''
    tyre_season = 0
    tyre_brand = ''
    res = ''
    if url_parts.include?('shiny') && url_parts != '' &&
      url_parts.any? { |part| part.match(/w-\d+/) } &&
      url_parts.any? { |part| part.match(/h-\d+/) } &&
      url_parts.any? { |part| part.match(/r-\d+/) }

      url_parts.each do |el|

        case el
        when /w-\d+/
          tyre_w = el.to_s.gsub('w-', '')
        when /h-\d+/
          tyre_h = el.to_s.gsub('h-', '')
        when /r-\d+/
          tyre_r = el.to_s.gsub('r-', '')
        when 'letnie'
          tyre_season = 1
        when 'zimnie'
          tyre_season = 2
        when 'vsesezonie'
          tyre_season = 3
        else
          tyre_brand = el if Brand.exists?(url: el)

        end

      end

      res += str_head(tyre_r, tyre_w, tyre_h)
      res += block_str_size(tyre_r, tyre_w, tyre_h)

      res += str_brand(tyre_brand) if tyre_brand != ''
      res += str_season(tyre_season) if tyre_season > 0
      res += str_end

    end
    res
  end

  def block_str_size(tyre_r, tyre_w, tyre_h)
    arr = []
    result = ''
    4.times do |i|
      str = send("str_size#{i + 1}", tyre_r, tyre_w, tyre_h)
      str.gsub!(/(^[^:]*):/, '<b>\1:</b>')
      str.gsub!('<b><p>', '<p><b>')
      str.gsub!('<b><li>', '<li><b>')
      str.gsub!('<b><ul>', '<ul><b>')
      str.gsub!("<b>\n<i>", "\n<i><b>")
      arr << str
    end
    # arr.shuffle!
    arr.each do |el|
      result += el
    end
    result
  end

  def to_cyrillic(str)
    latin_chars = 'qwertyuiop[]asdfghjkl;\'zxcvbnm,.`'
    cyrillic_chars = 'йцукенгшщзхъфывапролджэячсмитьбю.'

    str.tr(latin_chars, cyrillic_chars)
  end

  def convert_to_cyrillic(word)
    Translit.convert(word, :russian)
  end

  def str_size1(tyre_r, tyre_w, tyre_h)
    result = ''
    result += "<li>"
    result += TextError.where(type_line: "size1").order("RANDOM()").first&.line
    result += "\n<ul>\n"
    result += "<i>Пример:  купить шины на  R#{tyre_r} #{tyre_w} #{tyre_h},  #{tyre_h}R#{tyre_r} на #{tyre_w}, р#{tyre_r} #{tyre_w} #{tyre_h} </i>"
    result += "</ul>\n"
    result += "</li>\n"
    result
  end

  def str_size2(tyre_r, tyre_w, tyre_h)
    result = ''
    result += "<li>"
    result += TextError.where(type_line: "size2").order("RANDOM()").first&.line
    result += "\n<ul>\n"
    result += "<i>Пример:  резину #{tyre_w}-#{tyre_h}-#{tyre_r}, купить #{tyre_w}х#{tyre_h} р#{tyre_r}, #{tyre_w}x#{tyre_h} r#{tyre_r} </i>"
    result += "</ul>\n"
    result += "</li>\n"
    result
  end

  def str_size3(tyre_r, tyre_w, tyre_h)
    result = ''
    result += "<li>"
    result += TextError.where(type_line: "size3").order("RANDOM()").first&.line
    result += "\n<ul>\n"
    result += "<i>Пример:  #{tyre_w}/#{tyre_h}/#{tyre_r} в Киеве, #{tyre_w} #{tyre_h} #{tyre_r} купить.</i>"
    result += "</ul>\n"
    result += "</li>\n"
    result
  end
  #  175/70r13, 175 70 r 13 82t, 175 70 р 13,
  def str_size4(tyre_r, tyre_w, tyre_h)
    result = ''
    result += "<li>"
    result += TextError.where(type_line: "size4").order("RANDOM()").first&.line
    result += "\n<ul>\n"
    result += "<i>Пример: Сколько стоит #{tyre_w} на #{tyre_r}?\n  Какая цена  #{tyre_w} #{tyre_h} r #{tyre_r} ?</i>"
    result += "</ul>\n"
    result += "</li>\n"
    result
  end

  def str_brand(tyre_brand)
    result = ''
    result += "<li>"
    result += TextError.where(type_line: "brand").order("RANDOM()").first&.line
    result += "\n<ul>\n"
    result += "<i>Пример: #{convert_to_cyrillic(tyre_brand)} - набор наименования бренда кириллицей, \n"
    result += "а '#{to_cyrillic(tyre_brand)}' - не была переключена раскладка клавиатуры при наборе '#{tyre_brand}'. </i>"
    result += "</ul>\n"
    result += "</li>\n"
    result
  end

  def str_season(tyre_season)
    result = ''
    result += "<p>"
    result += TextError.where(type_line: "season").order("RANDOM()").first&.line

    case tyre_season
    when 1
      result += " Пример: летние шины, резина на лето. "
    when 2
      result += " Пример: зимняя резина, шины на зиму, липучки."
    when 3
      result += " Пример: универсальная резина, всесезонные шины, для любой погоды."
    end

    result += "</p>\n"
    result
  end

  def str_head(tyre_r, tyre_w, tyre_h)
    result = ''
    result += "<h3>"
    result += TextError.where(type_line: "h2").order("RANDOM()").first&.line
    result.gsub!('[size]',"#{tyre_w}/#{tyre_h} R#{tyre_r}")
    result += "</h3>\n"
    result += "<p>"
    result += TextError.where(type_line: "start").order("RANDOM()").first&.line
    result += "</p>\n"
    if result !~ /:(\s+|)<\/p>$/
      result += "<p>"
      result += " " + TextError.where(type_line: "typo").order("RANDOM()").first&.line
      result += "</p>\n"
    end
    result
  end

  def str_end
    result = ''
    result += "<p>"
    result += TextError.where(type_line: "end").order("RANDOM()").first&.line
    result += "</p>\n"
    result
  end

end