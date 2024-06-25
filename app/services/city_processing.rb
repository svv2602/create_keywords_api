# app/services/city_processing.rb

module CityProcessing
  require 'city/exercise.rb'

  def ru_end_of_request(city_params)
    str = "Требования к тексту:"
    str += "\n"
    str += "Стиль: Информационный, с элементами экспертного мнения."
    str += "\n"
    str += "Объем текста должен составлять от 500 до 1000 слов. Заголовки следует оформить тегами h2 или h3, а текст — в тегах p. Использование тегов ul или ol для структурирования информации также допустимо. "
    str += "\n"
    str += "Использовать простые и понятные выражения, избегать сложных технических терминов без пояснений."
    str += "\n"
    str += "Включить реальные примеры и статистические данные для подкрепления основных тезисов."
    str += "\n"
    str += " Уделить внимание логичности и последовательности изложения материала."
    str += "\n"
    str += " Целевая аудитория: Водители всех категорий, от начинающих до опытных автолюбителей, интересующиеся безопасностью и эффективностью своего автомобиля."
    str += "\n"
    str += "Ключевые слова: Обязательно Включить в текст следующие ключевые слова и фразы: 'купить шины ', 'купить резину', #{city_params}"
    str += "\n"
    str += "Обязательно: В тексте использовать слово 'резина' как синонимум для слова 'шины' в половине случаев, стобы избежать переспама. "
    str += "\n"
    str += "В тексте не должно быть упоминаний названий городов, отличных от города #{city_params}"
    str += "\n"
    str += "Текст должен быть русском языке и оптимизирован для поисковых запросов "
    str += "\n"

    # str += "Покажи результат вместе с тегами"
    str

  end

  def ua_end_of_request(city_params)

    str = "Вимоги до тексту:"
    str += "\n"
    str += "Стиль: Інформаційний, з елементами експертної думки."
    str += "\n"
    str += "Обсяг тексту має становити від 500 до 1000 слів. Заголовки слід оформити тегами h2 або h3, а текст — у тегах p. Використання тегів ul або ol для структурування інформації також допустиме."
    str += "\n"
    str += "Використовувати прості та зрозумілі вирази, уникати складних технічних термінів без пояснень."
    str += "\n"
    str += "Включити реальні приклади та статистичні дані для підтвердження основних тез."
    str += "\n"
    str += "Приділити увагу логічності та послідовності викладу матеріалу."
    str += "\n"
    str += "Цільова аудиторія: Водії всіх категорій, від початківців до досвідчених автолюбителів, які цікавляться безпекою та ефективністю свого автомобіля."
    str += "\n"
    str += "Ключові слова: Обов'язково включити в текст такі ключові слова та фрази: 'купити шини', 'купити гуму', #{city_params}"
    str += "\n"
    str += "Обов'язково: У тексті використовувати слово 'гума' як синонім до слова 'шини' в половині випадків, щоб уникнути переспаму."
    str += "\n"
    str += "У тексті не повинно бути згадок назв міст, відмінних від міста #{city_params}"
    str += "\n"
    str += "Текст має бути українською мовою та оптимізований для пошукових запитів."
    str += "\n"

    str += "Покажи результат разом з тегами"
    str

  end

  def generate_text_for_city

    result = ""
    city_params = params[:city]
    language = params[:language]

    array_brand = ['bridgestone', 'continental', 'doublestar', 'firestone', 'goodyear', 'hankook', 'kumho', 'michelin', 'nokian', 'rosava', 'taurus'].sample(4)
    list_brand = array_brand.join(", ")

    EXERCIZES[language.to_sym].each do |key, value|
      text = value.sample
      if text
        topics = "Напиши текст для города #{city_params}' "
        topics += text
        topics += "Список брендов: #{list_brand}" if key == :why_choose_prokoleso
        topics += language == "ru" ? ru_end_of_request(city_params) : ua_end_of_request(city_params)
        topics += "\n"

        if key == :faqs
          topics += "Из текста сделать раздел вопросов и ответов с микроразметкой 'https://schema.org/FAQPage'. Обязательно: itemscope itemtype='https://schema.org/FAQPage' - оборачивает весь FAQ-контент; itemscope itemprop='mainEntity' itemtype='https://schema.org/Question' - оборачивает каждый отдельный вопрос и его ответ; itemprop='name' - применено к элементу, содержащему текст вопроса; itemscope itemprop='acceptedAnswer' itemtype='https://schema.org/Answer' - оборачивает ответ; itemprop='text' - применено к элементу, содержащему текст ответа."
          topics += "\n"
          topics += "Пример правильного использования: <div itemscope itemprop='acceptedAnswer' itemtype='https://schema.org/Answer'>"
          topics += "\n"
          topics += "Внимание! itemprop='mainEntity' не должен находиться на элементе h2. Вместо этого, mainEntity с типом Question должен оборачивать весь блок, включая вопрос и ответ. Также элемент ответа должен быть обернут в acceptedAnswer с типом Answer."
          topics += "\n"
          topics += "В ответ вывести только содержание раздела <body> "
          topics += "\n"
        end

        topics += "Покажи результат с тегами."
        new_text = ContentWriter.new.write_seo_city(topics)
        new_text = new_text['choices'][0]['message']['content'].strip if new_text
        if key == :faqs
          new_text = new_text.sub(/^.*?(?=<div)/, '')
          new_text = new_text.sub(/(.*div>).*/) { $1 }
          new_text = new_text.gsub(/```|html|<(\/|)body>/, '')
        end

        result += new_text
      end

    end

    array_brand.each do |value|
      result = result.sub(/#{value}/i, "<a href='https://prokoleso.ua/shiny/#{value}/'>#{value.capitalize}</a>")
    end

    result

  end

end