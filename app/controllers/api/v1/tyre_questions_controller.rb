# app/controllers/api/openai_controller.rb

class Api::V1::TyreQuestionsController < ApplicationController
  include ServiceTable

  def questions

    list_questions = []

    # формирование основного блока вопрос ответ
    rand(2..3).times do
      list_questions << question unless question[:question] == ""
    end

    # list_questions << question_brand

    render json: { list_questions: list_questions }
  end

  def question
    # Используется для таблицы вопросов по легковым шинам
    table = 'TyresFaq'
    table_copy = table + 'Copy' # Преобразуем имя таблицы-копии
    copy_table_to_table_copy_if_empty(table, table_copy)
    question = find_and_destroy_random_record(table_copy).question
    # puts "question = #{question}"

    # Делается рерайт полученного случайного вопроса
    topics = sinonim("Сделай рерайт вопроса: #{question}. Ответ оберни в квадратные скобки.")

    question = ContentWriter.new.write_draft_post(topics, 150)['choices'][0]['message']['content'].strip
    # puts "question new = #{question}"
    question = format_str(question)
    # Получение ответа на вопрос
    topics = "Дай краткий ответ, не более 300 печатных символов, на вопрос: #{question}. Ответ оберни в квадратные скобки"
    answer = ContentWriter.new.write_draft_post(topics, 500)
    answer = answer['choices'][0]['message']['content'].strip
    # answer = format_str(answer)
    rezult = { question: question, answer: answer }
    # render json: { question: question, answer: answer }
    # puts "answer new = #{answer}"
  end

  def sinonim(str)
    puts "str ===== #{str}"
    rand(0..20) % 2 ? str += " Вместо слова 'шины' необходимо использовать синонимы" : str
    str
  end

  def question_brand
    questions = [
      { question: 'Топ производителей шин, представленных на сайте Prokoleso ', url: 'https://prokoleso.ua/shiny/' },
      { question: 'Топ производителей летних шин, представленных на сайте Prokoleso', url: 'https://prokoleso.ua/shiny/letnie/' },
      { question: 'Топ производителей зимних шин, представленных на сайте Prokoleso', url: 'https://prokoleso.ua/shiny/zimnie/' },
      { question: 'Топ производителей всесезонных шин, представленных на сайте Prokoleso', url: 'https://prokoleso.ua/shiny/vsesezonie/' },
      { question: 'Кто входит в список лучших производителей шин?', url: 'https://prokoleso.ua/shiny/' },
      { question: 'Кто входит в список лучших производителей летних шин?', url: 'https://prokoleso.ua/shiny/letnie/' },
      { question: 'Кто входит в список лучших производителей зимних шин?', url: 'https://prokoleso.ua/shiny/zimnie/' },
      { question: 'Кто входит в список лучших производителей всесезонных шин? ', url: 'https://prokoleso.ua/shiny/vsesezonie/' },
      { question: 'Кто из известных шинных брендов представлен на сайте prokoleso.ua?', url: 'https://prokoleso.ua/shiny/' },
      { question: 'список лучших производителей шин', url: 'https://prokoleso.ua/shiny/' },
      { question: 'Лучшие производители летних шин ', url: 'https://prokoleso.ua/shiny/letnie/' },
      { question: 'Лучшие производители зимних шин', url: 'https://prokoleso.ua/shiny/zimnie/' },
      { question: 'Лучшие производители всесезонных шин', url: 'https://prokoleso.ua/shiny/vsesezonie/' },
      { question: 'Лучшие производители летних шин, представленные на сайте prokoleso.ua', url: 'https://prokoleso.ua/shiny/letnie/' },
      { question: 'Лучшие производители зимних шин, представленные на сайте prokoleso.ua', url: 'https://prokoleso.ua/shiny/zimnie/' },
      { question: 'Лучшие производители всесезонных шин, представленные на сайте prokoleso.ua', url: 'https://prokoleso.ua/shiny/vsesezonie/' },
      { question: 'Какие бренды шин рекомендуются для зимы?', url: 'https://prokoleso.ua/shiny/zimnie/' },
      { question: 'Какие бренды шин рекомендуются для лета?', url: 'https://prokoleso.ua/shiny/letnie/' },

    ]

    brand = [
      { name_brand: 'Barum', alias: 'barum' },
      { name_brand: 'BFGoodrich', alias: 'bfgoodrich' },
      { name_brand: 'Bridgestone', alias: 'bridgestone' },
      { name_brand: 'Continental', alias: 'continental' },
      { name_brand: 'Cooper', alias: 'cooper' },
      { name_brand: 'Debica', alias: 'debica' },
      { name_brand: 'Doublestar', alias: 'doublestar' },
      { name_brand: 'Dunlop', alias: 'dunlop' },
      { name_brand: 'Evergreen', alias: 'evergreen' },
      { name_brand: 'Falken', alias: 'falken' },
      { name_brand: 'Federal', alias: 'federal' },
      { name_brand: 'Firestone', alias: 'firestone' },
      { name_brand: 'Fulda', alias: 'fulda' },
      { name_brand: 'Gislaved', alias: 'gislaved' },
      { name_brand: 'GoodYear', alias: 'goodyear' },
      { name_brand: 'Grenlander', alias: 'grenlander' },
      { name_brand: 'GTRadial', alias: 'gtradial' },
      { name_brand: 'Hankook', alias: 'hankook' },
      { name_brand: 'HiFly', alias: 'hifly' },
      { name_brand: 'Kleber', alias: 'kleber' },
      { name_brand: 'Kormoran', alias: 'kormoran' },
      { name_brand: 'Kumho', alias: 'kumho' },
      { name_brand: 'Lassa', alias: 'lassa' },
      { name_brand: 'Laufenn', alias: 'laufenn' },
      { name_brand: 'Marshal', alias: 'marshal' },
      { name_brand: 'Matador', alias: 'matador' },
      { name_brand: 'Maxxis', alias: 'maxxis' },
      { name_brand: 'Michelin', alias: 'michelin' },
      { name_brand: 'Nexen', alias: 'nexen' },
      { name_brand: 'Nokian', alias: 'Tyres' },
      { name_brand: 'Orium', alias: 'orium' },
      { name_brand: 'Petlas', alias: 'petlas' },
      { name_brand: 'Pirelli', alias: 'pirelli' },
      { name_brand: 'Riken', alias: 'riken' },
      { name_brand: 'Roadstone', alias: 'roadstone' },
      { name_brand: 'Rosava', alias: 'rosava' },
      { name_brand: 'Sailun', alias: 'sailun' },
      { name_brand: 'Sava', alias: 'sava' },
      { name_brand: 'Semperit', alias: 'semperit' },
      { name_brand: 'Starmaxx', alias: 'starmaxx' },
      { name_brand: 'Strial', alias: 'strial' },
      { name_brand: 'Sumitomo', alias: 'sumitomo' },
      { name_brand: 'Taurus', alias: 'taurus' },
      { name_brand: 'Tigar', alias: 'tigar' },
      { name_brand: 'Toyo', alias: 'toyo' },
      { name_brand: 'Uniroyal', alias: 'uniroyal' },
      { name_brand: 'Viking', alias: 'viking' },
      { name_brand: 'Vredestein', alias: 'vredestein' },
      { name_brand: 'Yokohama', alias: 'yokohama' }

    ]
    question_random = questions.sample
    answer = ""
    topics = "Сделай рерайт вопроса: #{question_random[:question]}. Ответ оберни в квадратные скобки"
    question = ContentWriter.new.write_draft_post(topics, 150)['choices'][0]['message']['content'].strip
    question = format_str(question)
    random_brands = brand.sample(10)
    random_brands.each_with_index do |el, i|
      answer += "<a href='#{question_random[:url]}#{el[:alias]}/'>#{i + 1}. #{el[:name_brand]}</a>    "
    end
    rezult = { question: question, answer: "[#{answer}]" }
  end

  def format_str(str)
    # обработка ошибок
    # 1. оставляем из ответа openai только то, что в первых []-скобках
    str = str.split(']').first.strip + "]"
    # 2. удаляем из ответа все, что осталось в []-скобках
    # (иногда бывает ответ типа: [text1[text2]])
    str = str.gsub(/\[.*?\]/, '') if str =~ /(\S|\s)\[/

  end

end