class Api::V1::TextErrorController < ApplicationController
  include StringProcessing
  def text_line
    # test_url = 'https://prokoleso.ua/shiny/letnie/taurus/w-175/h-70/r-13/'
    # url = CGI::unescape(test_url) # возвращает URL обратно в незакодированном виде
    # GET /text_line?url=https%3A%2F%2Fprokoleso.ua%2Fshiny%2Fw-175%2Fh-70%2Fr-13%2F
    # url = CGI::unescape(params[:url]) # возвращает URL обратно в незакодированном виде

    result = arr_url_result_str

    render json: { result: result }
    puts result
  end

  def encoded_url(url)
    # тестовый для проверки url
    CGI::escape(url)
    # encoded_url = CGI::escape('https://prokoleso.ua/shiny/w-175/h-70/r-13/')
    # => "https%3A%2F%2Fprokoleso.ua%2Fshiny%2Fw-175%2Fh-70%2Fr-13%2F"
  end


  def arr_url_result_str
    res = ''
    url_param = url_shiny_hash_params
    if !url_param.empty?
      res += str_head(url_param[:tyre_r], url_param[:tyre_w], url_param[:tyre_h])
      res += block_str_size(url_param[:tyre_r], url_param[:tyre_w], url_param[:tyre_h])

      res += str_brand( url_param[:tyre_brand]) if url_param[:tyre_brand] != ""
      res += str_season( url_param[:tyre_season],
                         url_param[:tyre_r],
                         url_param[:tyre_w],
                         url_param[:tyre_h]) if url_param[:tyre_season] > 0
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
    arr.shuffle!
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
    result += "<i>Пример:  резину #{tyre_w}-#{tyre_h}-#{tyre_r},  #{tyre_w}х#{tyre_h} р#{tyre_r}, #{tyre_w}x#{tyre_h} r#{tyre_r} купить в Киеве</i>"
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

  def str_season(tyre_season, tyre_r, tyre_w, tyre_h)
    result = ''
    result += "<p>"
    result += TextError.where(type_line: "season").order("RANDOM()").first&.line
    result += " Пример запроса с указанием сезонности: "
    case tyre_season
    when 1
      result += "летние шины #{tyre_w} #{tyre_h} #{tyre_r} , резина #{tyre_w}/#{tyre_h} r#{tyre_r} купить на лето. "
    when 2
      result += "зимняя резина #{tyre_w} #{tyre_h} #{tyre_r} , шины #{tyre_w}/#{tyre_h} r#{tyre_r} купить на зиму, липучки."
    when 3
      result += "универсальная резина #{tyre_w}/#{tyre_h} r#{tyre_r}, всесезонные шины #{tyre_w} #{tyre_h} #{tyre_r} купить, для любой погоды."
    end

    result += "</p>\n"
    result
  end

  def str_head(tyre_r, tyre_w, tyre_h)
    result = ''
    result += "<h3>"
    result += TextError.where(type_line: "h2").order("RANDOM()").first&.line
    result.gsub!('[size]', "#{tyre_w} #{tyre_h} R#{tyre_r}")
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