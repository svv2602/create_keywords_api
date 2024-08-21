# app/services/index_page_google.rb


require 'googleauth'
require 'google/apis/indexing_v3'

module IndexPageGoogle

  def urls_to_index_google(arr_url)
    # Создаем объект сервиса
    service = Google::Apis::IndexingV3::IndexingService.new
    result = ""
    # Загружаем credentials из файла
    key_file = Rails.root.join('lib', 'keys', 'prokoleso-64a13-8aed760d6616.json')
    # key_file = 'prokoleso-64a13-8aed760d6616.json'
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(key_file),
      scope: 'https://www.googleapis.com/auth/indexing'
    )

    # Добавляем к сервису авторизационные данные
    service.authorization = authorizer

    # Пример списка URL для индексации:
    urls_to_index = arr_url

    urls_to_index.each do |url|
      begin
        notification = Google::Apis::IndexingV3::UrlNotification.new(url: url, type: 'URL_UPDATED')
        service.publish_url_notification(notification)
        result += "#{url}  |\n"
        puts "Successfuly requested indexing for #{url}"
      rescue Google::Apis::Error => e
        puts "There was an error requesting indexing for #{url} : #{e.message}"
      end
    end
    result

  end


  def urls_sizes_to_index(width,height,diameter)
    urls_to_index = [
      "https://prokoleso.ua/shiny/w-#{width}/h-#{height}/r-#{diameter}",
      "https://prokoleso.ua/shiny/zimnie/w-#{width}/h-#{height}/r-#{diameter}",
      "https://prokoleso.ua/shiny/letnie/w-#{width}/h-#{height}/r-#{diameter}",
      "https://prokoleso.ua/shiny/vsesezonie/w-#{width}/h-#{height}/r-#{diameter}",
      "https://prokoleso.ua/ua/shiny/w-#{width}/h-#{height}/r-#{diameter}",
      "https://prokoleso.ua/ua/shiny/zimnie/w-#{width}/h-#{height}/r-#{diameter}",
      "https://prokoleso.ua/ua/shiny/letnie/w-#{width}/h-#{height}/r-#{diameter}",
      "https://prokoleso.ua/ua/shiny/vsesezonie/w-#{width}/h-#{height}/r-#{diameter}"
    ]
    urls_to_index
  end

  def urls_articles_to_index(article)
    article = article.gsub('"', "")
    puts "z tut article = #{article}"
    return [] if article.nil? or !article.start_with?("https://prokoleso.ua/")
    puts "z tut article = #{article}"
    str = article.sub("https://prokoleso.ua/", "")
    str =  str.sub(/\Aua\//, '')
    urls_to_index = [
      "https://prokoleso.ua/#{str}",
      "https://prokoleso.ua/ua/#{str}"
    ]
    puts urls_to_index.inspect
    urls_to_index
  end

end