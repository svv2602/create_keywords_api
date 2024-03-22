# app/services/copy_text_optimization.rb
require 'json'
require_relative '../services/dictionaries/replaсe_keyword_tyres'
require_relative '../../app/services/content_writer'
require_relative '../../app/services/string_processing'

class CopyTextOptimization

  def insert_season_url_new(text_test)
    # season = url_shiny_hash_params[:tyre_season]
    # season = url_shiny_hash_params[:tyre_season]
    text = text_test
    season = 2
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
    # arr_size = arr_size_to_error
    arr_size = ["196 666 6667", '4567890 456789', '345f3456', '345gf76h 678hg', 'efgh567']

    search_size = /\s+\d{3}([ \/.-xXхХ]*| на )\d{2}([ \/.-xXхХ]*| на )(|[ rRpPрР])([ \/.-xXхХ]*)\d{2}([.,]\d{1})?[ \/.-]*[ cCсС]*/
    search_size_2 = /(на |)[ rRpPрР]\d{2}([.,]\d{1})?[ \/.-xXхХ]*[ cCсС]*([ \/.-xXхХ]*| на )\d{3}([ \/.-xXхХ]*| на )\d{2}/

    # ... Ваш код для определения переменных ...
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
        # ссылки на размеры
        regex = /#{value[:search_str]}\s*#{search_size}/
        match = line.match(regex)
        part_url = value[:value] == season ? '' : value[:value] + '/'
        if match && value[:state][:season_size]
          url = "<a href='https://prokoleso.ua/shiny/#{part_url}'>#{match[1]}</a>"
          line.sub!(regex, url)
          value[:state][:season_size] = false
          replaced = true
        end
        break if replaced
      end

      # if season != 0 && !replaced
      #   # part_url = "w-#{url_shiny_hash_params[:tyre_w]}/h-#{url_shiny_hash_params[:tyre_h]}/r-#{url_shiny_hash_params[:tyre_r]}/"
      #   part_url = "w-205/h-55/r-16/"
      #   str_search = /#{search_size}/
      #   url = "<a href='https://prokoleso.ua/shiny/#{part_url}'>#{arr_size[season]}</a>"
      #   replaced = !line.sub!(str_search, url).nil?
      # end

      line
    end.join("")

    # вернуть измененный текст
    text
  end

end

test = CopyTextOptimization.new

text = "



<h3> 5 причин выбрать зимние шины интернет-магазин летние шины  PROKOLESO для всесезонная резина шиныпокупки шин.</h3>
<h3> 5 причин выбрать зимние шины интернет-магазин летние шины  PROKOLESO для всесезонная резина шиныпокупки шин.</h3>
<h3> 5 причин выбрать зимние шины интернет-магазин летние шины  PROKOLESO для всесезонная резина шиныпокупки шин.</h3>
<h3> 5 причин выбрать зимние шины 205 55 18 интернет-магазин летние шины  PROKOLESO для всесезонная резина шиныпокупки шин.</h3>




"
result = test.insert_season_url_new(text)
puts "=" * 120
puts "test.chars_count(text) = #{result}"
puts "=" * 120
puts "=" * 120
puts "=" * 120


