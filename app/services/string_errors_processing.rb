# app/services/string_errors_processing.rb
module StringErrorsProcessing

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

      res += str_brand(url_param[:tyre_brand]) if url_param[:tyre_brand] != ""
      res += str_season(url_param[:tyre_season],
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
      # str.gsub!(/(^[^:]*):/, '<b>\1:</b>')
      # str.gsub!('<b><p>', '<p><b>')
      # str.gsub!('<b><li>', '<li><b>')
      # str.gsub!('<b><ul>', '<ul><b>')
      # str.gsub!("<b>\n<i>", "\n<i><b>")
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
    result += "<p>"
    randdom_record = TextError.where(type_line: "size1").order("RANDOM()").first
    if url_type_ua?
      result += randdom_record&.line_ua
      result += "\n</p>\n<ul>\n<li>\n"
      result += "<i>Приклад: купити шини на R#{tyre_r} #{tyre_w} #{tyre_h},  #{tyre_h}R#{tyre_r} на #{tyre_w}, р#{tyre_r} #{tyre_w} #{tyre_h} </i>"

    else
      result += randdom_record&.line
      result += "\n</p>\n<ul>\n<li>\n"
      result += "<i>Пример:  купить шины на  R#{tyre_r} #{tyre_w} #{tyre_h},  #{tyre_h}R#{tyre_r} на #{tyre_w}, р#{tyre_r} #{tyre_w} #{tyre_h} </i>"

    end

    result += "</li>\n"
    result += "</ul>\n"
    result
  end

  def str_size2(tyre_r, tyre_w, tyre_h)
    result = ''
    result += "<p>"
    randdom_record = TextError.where(type_line: "size2").order("RANDOM()").first
    if url_type_ua?
      result += randdom_record&.line_ua
      result += "\n</p>\n<ul>\n<li>\n"
      result += "<i>Приклад:  резину #{tyre_w}-#{tyre_h}-#{tyre_r},  #{tyre_w}х#{tyre_h} р#{tyre_r}, #{tyre_w}x#{tyre_h} r#{tyre_r} купити у Києві</i>"

    else
      result += randdom_record&.line
      result += "\n</p>\n<ul>\n<li>\n"
      result += "<i>Пример:  резину #{tyre_w}-#{tyre_h}-#{tyre_r},  #{tyre_w}х#{tyre_h} р#{tyre_r}, #{tyre_w}x#{tyre_h} r#{tyre_r} купить в Киеве</i>"

    end

    result += "</li>\n"
    result += "</ul>\n"
    result
  end

  def str_size3(tyre_r, tyre_w, tyre_h)
    result = ''
    result += "<p>"

    randdom_record = TextError.where(type_line: "size3").order("RANDOM()").first
    if url_type_ua?
      result += randdom_record&.line_ua
      result += "\n</p>\n<ul>\n<li>\n"
      result += "<i>Пример:  #{tyre_w}/#{tyre_h}/#{tyre_r} Київ, #{tyre_w} #{tyre_h} #{tyre_r} купити.</i>"

    else
      result += randdom_record&.line
      result += "\n</p>\n<ul>\n<li>\n"
      result += "<i>Пример:  #{tyre_w}/#{tyre_h}/#{tyre_r} в Киеве, #{tyre_w} #{tyre_h} #{tyre_r} купить.</i>"

    end

    result += "</li>\n"
    result += "</ul>\n"
    result

  end

  #  175/70r13, 175 70 r 13 82t, 175 70 р 13,
  def str_size4(tyre_r, tyre_w, tyre_h)
    result = ''
    result += "<p>"

    randdom_record = TextError.where(type_line: "size4").order("RANDOM()").first
    if url_type_ua?
      result += randdom_record&.line_ua
      result += "\n</p>\n<ul>\n<li>\n"
      result += "<i>Приклад: Скільки коштує #{tyre_w} на #{tyre_r}?\n Яка ціна  #{tyre_w} #{tyre_h} r #{tyre_r} ?</i>"

    else
      result += randdom_record&.line
      result += "\n</p>\n<ul>\n<li>\n"
      result += "<i>Пример: Сколько стоит #{tyre_w} на #{tyre_r}?\n Какая цена  #{tyre_w} #{tyre_h} r #{tyre_r} ?</i>"

    end

    result += "</li>\n"
    result += "</ul>\n"
    result

  end

  def str_brand(tyre_brand)
    result = ''
    result += "<p>"

    randdom_record = TextError.where(type_line: "brand").order("RANDOM()").first
    if url_type_ua?
      result += randdom_record&.line_ua
      result += "\n</p>\n<ul>\n<li>\n"
      result += "<i>Приклад: #{convert_to_cyrillic(tyre_brand)} - набір найменування бренду кирилицею, \n"
      result += "а '#{to_cyrillic(tyre_brand)}' - не було переключено розкладку клавіатури при наборі назви бренду '#{tyre_brand}'. </i>"

    else
      result += randdom_record&.line
      result += "\n</p>\n<ul>\n<li>\n"
      result += "<i>Пример: #{convert_to_cyrillic(tyre_brand)} - набор наименования бренда кириллицей, \n"
      result += "а '#{to_cyrillic(tyre_brand)}' - не была переключена раскладка клавиатуры при наборе '#{tyre_brand}'. </i>"

    end


    result += "</li>\n"
    result += "</ul>\n"
    result
  end

  def str_season(tyre_season, tyre_r, tyre_w, tyre_h)
    result = ''
    result += "<p>\n"
    randdom_record = TextError.where(type_line: "season").order("RANDOM()").first

    if url_type_ua?
      result += randdom_record&.line_ua

      result += " Приклад запиту із зазначенням сезонності: "
      case tyre_season
      when 1
        result += "літні шини #{tyre_w} #{tyre_h} #{tyre_r} , резина #{tyre_w}/#{tyre_h} r#{tyre_r} купити на літо. "
      when 2
        result += "зимова гума #{tyre_w} #{tyre_h} #{tyre_r} , шини #{tyre_w}/#{tyre_h} r#{tyre_r} купити на зиму, липучки."
      when 3
        result += "універсальна гума #{tyre_w}/#{tyre_h} r#{tyre_r}, всесезонні шини #{tyre_w} #{tyre_h} #{tyre_r} купити, для будь-якої погоди."
      end

    else
      result += randdom_record&.line

      result += " Пример запроса с указанием сезонности: "
      case tyre_season
      when 1
        result += "летние шины #{tyre_w} #{tyre_h} #{tyre_r} , резина #{tyre_w}/#{tyre_h} r#{tyre_r} купить на лето. "
      when 2
        result += "зимняя резина #{tyre_w} #{tyre_h} #{tyre_r} , шины #{tyre_w}/#{tyre_h} r#{tyre_r} купить на зиму, липучки."
      when 3
        result += "универсальная резина #{tyre_w}/#{tyre_h} r#{tyre_r}, всесезонные шины #{tyre_w} #{tyre_h} #{tyre_r} купить, для любой погоды."
      end

    end


    result += "</p>\n"
    result
  end

  def str_head(tyre_r, tyre_w, tyre_h)
    result = ''
    result += "<h3>"
    randdom_record = TextError.where(type_line: "h2").order("RANDOM()").first
    result += url_type_ua? ? randdom_record&.line_ua : randdom_record&.line
    # result += TextError.where(type_line: "h2").order("RANDOM()").first&.line
    result.gsub!('[size]', "#{tyre_w} #{tyre_h} R#{tyre_r}")
    result += "</h3>\n"
    result += "<p>"
    randdom_record = TextError.where(type_line: "start").order("RANDOM()").first
    result += url_type_ua? ? randdom_record&.line_ua : randdom_record&.line
    # result += TextError.where(type_line: "start").order("RANDOM()").first&.line
    result += "</p>\n"
    if result !~ /:(\s+|)<\/p>$/
      result += "<p>"
      result += " "
      randdom_record = TextError.where(type_line: "typo").order("RANDOM()").first
      result += url_type_ua? ? randdom_record&.line_ua : randdom_record&.line
      # result += " " + TextError.where(type_line: "typo").order("RANDOM()").first&.line
      result += "</p>\n"
    end
    result
  end

  def str_end
    result = ''
    result += "<p>"
    randdom_record = TextError.where(type_line: "end").order("RANDOM()").first
    result += url_type_ua? ? randdom_record&.line_ua : randdom_record&.line
    # result += TextError.where(type_line: "end").order("RANDOM()").first&.line
    result += "</p>\n"
    result
  end

end