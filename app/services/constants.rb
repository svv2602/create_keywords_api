# Константы в виде массива
# ARR_CONST = {
# questions : [
#
# ],
#   aliases : [
#
# ]
# }
# Используются в app/controllers/api/v1/tyre_questions_controller.rb
# метод: questions_dop

module Constants
  # Общие страницы - города
  CITIES = {
    questions: [
      { question: 'Где я могу получить шины, купленные в вашем магазине?', url: 'https://prokoleso.ua/' },
      { question: 'В какие города Вы доставляете купленный у Вас товар?', url: 'https://prokoleso.ua/' },
      { question: 'Список населенных пунктов Украины, в которые осуществляется доставка', url: 'https://prokoleso.ua/' },
      { question: 'В какие населенные пункты осуществляется курьерская доставка?', url: 'https://prokoleso.ua/' },
      { question: 'В какие населенные пункты осуществляется адресная доставка "Новой Почты"?', url: 'https://prokoleso.ua/' },
      { question: 'В какие населенные пункты уже отправлялись товары, купленные в вашем магазине в этом году?', url: 'https://prokoleso.ua/' },
      { question: 'В каких городах я могу получить шины,  купленные в prokoleso.ua?', url: 'https://prokoleso.ua/' },
      { question: 'В каких городах можно получить товар,  приобретенный в prokoleso.ua?', url: 'https://prokoleso.ua/' },
      { question: 'Где в Украине я могу получить шины, оплаченные наложенным платежом?', url: 'https://prokoleso.ua/' }
    ],
    aliases: [
      { name: 'Александрия', alias: 'shiny-aleksandriya' },
      { name: 'Апостолово', alias: 'shiny-apostolovo' },
      { name: 'Ахтырка', alias: 'shiny-akhtyrka' },
      { name: 'Белая Церковь', alias: 'shiny-belaya-tserkov' },
      { name: 'Белгород-Днестровский', alias: 'shiny-belgorod-dnestrovskiy' },
      { name: 'Бердичев', alias: 'shiny-berdichev' },
      { name: 'Бердянск', alias: 'shiny-berdyansk' },
      { name: 'Борисполь', alias: 'shiny-borispol' },
      { name: 'Боярка', alias: 'shiny-boyarka' },
      { name: 'Бровары', alias: 'shiny-brovary' },
      { name: 'Буча', alias: 'shiny-bucha' },
      { name: 'Васильков', alias: 'shiny-vasilkov' },
      { name: 'Винница', alias: 'shiny-vinnitsa' },
      { name: 'Вишневое', alias: 'shiny-vishnevoe' },
      { name: 'Вознесенск', alias: 'shiny-voznesensk' },
      { name: 'Вольногорск', alias: 'shiny-volnogorsk' },
      { name: 'Вышгород', alias: 'shiny-vyshgorod' },
      { name: 'Гайсин', alias: 'shiny-gaysin' },
      { name: 'Глухов', alias: 'shiny-glukhov-sumskaya-obl-' },
      { name: 'Горишние Плавные', alias: 'shiny-gorishnie-plavni' },
      { name: 'Днепр', alias: 'shiny-dnepr' },
      { name: 'Дубно', alias: 'shiny-dubno' },
      { name: 'Желтые Воды', alias: 'shiny-zheltye-vody' },
      { name: 'Житомир', alias: 'shiny-zhitomir' },
      { name: 'Жмеринка', alias: 'shiny-zhmerinka' },
      { name: 'Запорожье', alias: 'shiny-zaporozhe' },
      { name: 'Здолбунов', alias: 'shiny-zdolbunov' },
      { name: 'Знаменка', alias: 'shiny-znamenka-kirovogradskaya-obl' },
      { name: 'Ивано-Франковск', alias: 'shiny-ivano-frankovsk' },
      { name: 'Изюм', alias: 'shiny-izyum' },
      { name: 'Ирпень', alias: 'shiny-irpen' },
      { name: 'Казатин', alias: 'shiny-kazatin' },
      { name: 'Каменец-Подольский', alias: 'shiny-kamenets-podolskiy' },
      { name: 'Каменское', alias: 'shiny-kamenskoe-dnepropetrovskaya-obl' },
      { name: 'Канев', alias: 'shiny-kanev' },
      { name: 'Каховка', alias: 'shiny-kakhovka' },
      { name: 'Киев', alias: 'shiny-kiev' },
      { name: 'Кропивницкий', alias: 'shiny-kropivnitskiy' },
      { name: 'Ковель', alias: 'shiny-kovel' },
      { name: 'Конотоп', alias: 'shiny-konotop' },
      { name: 'Коростень', alias: 'shiny-korosten' },
      { name: 'Костополь', alias: 'shiny-kostopol' },
      { name: 'Краматорск', alias: 'shiny-kramatorsk' },
      { name: 'Кременчуг', alias: 'shiny-kremenchug' },
      { name: 'Кривой Рог', alias: 'shiny-krivoy-rog' },
      { name: 'Ладыжин', alias: 'shiny-ladyzhin' },
      { name: 'Лебедин', alias: 'shiny-lebedin-sumskaya-obl-' },
      { name: 'Лубны', alias: 'shiny-lubny' },
      { name: 'Луцк', alias: 'shiny-lutsk' },
      { name: 'Львов', alias: 'shiny-lvov' },
      { name: 'Марганец', alias: 'shiny-marganets' },
      { name: 'Мелитополь', alias: 'shiny-melitopol' },
      { name: 'Могилев-Подольский', alias: 'shiny-mogilev-podolskiy' },
      { name: 'Мукачево', alias: 'shiny-mukachevo' },
      { name: 'Нежин', alias: 'shiny-nezhin' },
      { name: 'Нетешин', alias: 'shiny-neteshin' },
      { name: 'Николаев', alias: 'shiny-nikolaev' },
      { name: 'Никополь', alias: 'shiny-nikopol-dnepropetrovskaya-obl-' },
      { name: 'Новая Каховка', alias: 'shiny-novaya-kakhovka' },
      { name: 'Нововолынск', alias: 'shiny-novovolynsk' },
      { name: 'Одесса', alias: 'shiny-odessa' },
      { name: 'Олешки', alias: 'shiny-alyeshki-khersonskaya-obl' },
      { name: 'Павлоград', alias: 'shiny-pavlograd' },
      { name: 'Первомайск', alias: 'shiny-pervomaysk-nikol-obl-pervomays-r-n' },
      { name: 'Подольск', alias: 'shiny-podolsk' },
      { name: 'Покров', alias: 'shiny-pokrov' },
      { name: 'Полтава', alias: 'shiny-poltava' },
      { name: 'Прилуки', alias: 'shiny-priluki' },
      { name: 'Ровно', alias: 'shiny-rovno' },
      { name: 'Ромны', alias: 'shiny-romny' },
      { name: 'Сарны', alias: 'shiny-sarny' },
      { name: 'Славута', alias: 'shiny-slavuta' },
      { name: 'Славянск', alias: 'shiny-slavyansk' },
      { name: 'Смело', alias: 'shiny-smela' },
      { name: 'Сумы', alias: 'shiny-sumy' },
      { name: 'Тернополь', alias: 'shiny-ternopol' },
      { name: 'Трускавец', alias: 'shiny-trostyanets-sumskaya-obl' },
      { name: 'Ужгород', alias: 'shiny-uzhgorod' },
      { name: 'Умань', alias: 'shiny-uman' },
      { name: 'Харьков', alias: 'shiny-kharkov' },
      { name: 'Херсон', alias: 'shiny-kherson' },
      { name: 'Хмельник', alias: 'shiny-khmelnik-vinnitskaya-obl-' },
      { name: 'Хмельницкий', alias: 'shiny-khmelnitskiy' },
      { name: 'Хуст', alias: 'shiny-khust' },
      { name: 'Черкассы', alias: 'shiny-cherkasi' },
      { name: 'Чернигов', alias: 'shiny-chernigov' },
      { name: 'Черновцы', alias: 'shiny-chernovtsy' },
      { name: 'Черноморск', alias: 'shiny-chernomorsk' },
      { name: 'Чортков', alias: 'shiny-chortkov' },
      { name: 'Шостка', alias: 'shiny-shostka' },
      { name: 'Энергодар', alias: 'shiny-energodar' },
      { name: 'Южноукраинск', alias: 'shiny-yuzhnoukrainsk' }
    ]

  }

  # ================================
  # Легковые шины бренды
  BRANDS = {
    questions: [
      { question: 'Топ производителей шин, представленных на сайте Prokoleso ', url: 'https://prokoleso.ua/shiny/' },
      { question: 'Топ производителей летних шин, представленных на сайте Prokoleso', url: 'https://prokoleso.ua/shiny/letnie/' },
      { question: 'Топ производителей зимних шин, представленных на сайте Prokoleso', url: 'https://prokoleso.ua/shiny/zimnie/' },
      { question: 'Топ производителей всесезонных шин, представленных на сайте Prokoleso', url: 'https://prokoleso.ua/shiny/' },
      { question: 'Кто входит в список лучших производителей шин?', url: 'https://prokoleso.ua/shiny/' },
      { question: 'Кто входит в список лучших производителей летних шин?', url: 'https://prokoleso.ua/shiny/letnie/' },
      { question: 'Кто входит в список лучших производителей зимних шин?', url: 'https://prokoleso.ua/shiny/zimnie/' },
      { question: 'Кто входит в список лучших производителей всесезонных шин? ', url: 'https://prokoleso.ua/shiny/vsesezonie/' },
      { question: 'Кто из известных шинных брендов представлен на сайте prokoleso.ua?', url: 'https://prokoleso.ua/shiny/' },
      { question: 'список лучших производителей шин', url: 'https://prokoleso.ua/shiny/' },
      { question: 'Лучшие производители летних шин ', url: 'https://prokoleso.ua/shiny/letnie/' },
      { question: 'Лучшие производители зимних шин', url: 'https://prokoleso.ua/shiny/zimnie/' },
      { question: 'Лучшие производители всесезонных шин', url: 'https://prokoleso.ua/shiny/' },
      { question: 'Лучшие производители летних шин, представленные на сайте prokoleso.ua', url: 'https://prokoleso.ua/shiny/letnie/' },
      { question: 'Лучшие производители зимних шин, представленные на сайте prokoleso.ua', url: 'https://prokoleso.ua/shiny/zimnie/' },
      { question: 'Лучшие производители всесезонных шин, представленные на сайте prokoleso.ua', url: 'https://prokoleso.ua/shiny/vsesezonie/' },
      { question: 'Какие бренды шин рекомендуются для зимы?', url: 'https://prokoleso.ua/shiny/zimnie/' },
      { question: 'Какие бренды шин рекомендуются для лета?', url: 'https://prokoleso.ua/shiny/letnie/' },

    ],

    aliases: [
      { name: 'Barum', alias: 'barum' },
      { name: 'BFGoodrich', alias: 'bfgoodrich' },
      { name: 'Bridgestone', alias: 'bridgestone' },
      { name: 'Continental', alias: 'continental' },
      { name: 'Cooper', alias: 'cooper' },
      { name: 'Debica', alias: 'debica' },
      { name: 'Doublestar', alias: 'doublestar' },
      { name: 'Dunlop', alias: 'dunlop' },
      { name: 'Evergreen', alias: 'evergreen' },
      { name: 'Falken', alias: 'falken' },
      { name: 'Federal', alias: 'federal' },
      { name: 'Firestone', alias: 'firestone' },
      { name: 'Fulda', alias: 'fulda' },
      { name: 'Gislaved', alias: 'gislaved' },
      { name: 'GoodYear', alias: 'goodyear' },
      { name: 'Grenlander', alias: 'grenlander' },
      { name: 'GTRadial', alias: 'gtradial' },
      { name: 'Hankook', alias: 'hankook' },
      { name: 'HiFly', alias: 'hifly' },
      { name: 'Kleber', alias: 'kleber' },
      { name: 'Kormoran', alias: 'kormoran' },
      { name: 'Kumho', alias: 'kumho' },
      { name: 'Lassa', alias: 'lassa' },
      { name: 'Laufenn', alias: 'laufenn' },
      { name: 'Marshal', alias: 'marshal' },
      { name: 'Matador', alias: 'matador' },
      { name: 'Maxxis', alias: 'maxxis' },
      { name: 'Michelin', alias: 'michelin' },
      { name: 'Nexen', alias: 'nexen' },
      { name: 'Nokian', alias: 'Tyres' },
      { name: 'Orium', alias: 'orium' },
      { name: 'Petlas', alias: 'petlas' },
      { name: 'Pirelli', alias: 'pirelli' },
      { name: 'Riken', alias: 'riken' },
      { name: 'Roadstone', alias: 'roadstone' },
      { name: 'Rosava', alias: 'rosava' },
      { name: 'Sailun', alias: 'sailun' },
      { name: 'Sava', alias: 'sava' },
      { name: 'Semperit', alias: 'semperit' },
      { name: 'Starmaxx', alias: 'starmaxx' },
      { name: 'Strial', alias: 'strial' },
      { name: 'Sumitomo', alias: 'sumitomo' },
      { name: 'Taurus', alias: 'taurus' },
      { name: 'Tigar', alias: 'tigar' },
      { name: 'Toyo', alias: 'toyo' },
      { name: 'Uniroyal', alias: 'uniroyal' },
      { name: 'Viking', alias: 'viking' },
      { name: 'Vredestein', alias: 'vredestein' },
      { name: 'Yokohama', alias: 'yokohama' }

    ]
  }
  # Легковые шины - диаметры
  DIAMETERS = {
    questions: [
      { question: 'Самые распространенные посадочные диаметры у автошин', url: 'https://prokoleso.ua/shiny/' },
      { question: 'ТОП популярных посадочных диаметров для шин', url: 'https://prokoleso.ua/shiny/' },
      { question: 'ТОП популярных посадочных диаметров для шин, представленных на  prokoleso.ua', url: 'https://prokoleso.ua/shiny/' }

    ],
    aliases: [
      { name: 'R12', alias: 'r-12' },
      { name: 'R13', alias: 'r-13' },
      { name: 'R14', alias: 'r-14' },
      { name: 'R15', alias: 'r-15' },
      { name: 'R16', alias: 'r-16' },
      { name: 'R17', alias: 'r-17' },
      { name: 'R18', alias: 'r-18' },
      { name: 'R19', alias: 'r-19' },
      { name: 'R20', alias: 'r-20' },
      { name: 'R21', alias: 'r-21' },
      { name: 'R22', alias: 'r-22' },
      { name: 'R23', alias: 'r-23' },
      { name: 'R15c', alias: 'r-15c' },
      { name: 'R16c', alias: 'r-16c' },
      { name: 'R17c', alias: 'r-17c' },

    ]

  }
  # Легковые шины - размеры
  TOP_SIZE = {
    questions: [
      { question: 'Какие размеры шин являются наиболее популярными среди автолюбителей на вашем сайте?', url: 'https://prokoleso.ua/shiny/' },
      { question: 'Какие типоразмеры шин являются наиболее популярными ?', url: 'https://prokoleso.ua/shiny/' },
      { question: 'Самые распространенные типоразмеры шин', url: 'https://prokoleso.ua/shiny/' },
      { question: 'Популярные размеры шин для легковых автомобилей', url: 'https://prokoleso.ua/shiny/' },
      { question: 'Какие размеры шин для легковых автомобилей покупают у вас на сайте больше всего?', url: 'https://prokoleso.ua/shiny/' },
      { question: 'Какие размеры шин для легковых автомобилей покупают больше всего на prokoleso.ua?', url: 'https://prokoleso.ua/shiny/' },
      { question: 'Какие типоразмеры летних шин являются наиболее популярными ?', url: 'https://prokoleso.ua/shiny/letnie/' },
      { question: 'Самые распространенные типоразмеры летних шин', url: 'https://prokoleso.ua/shiny/letnie/' },
      { question: 'Размеры летних шин для легковых автомобилей', url: 'https://prokoleso.ua/shiny/letnie/' },
      { question: 'Какие размеры летних шин для  легковых автомобилей покупают больше всего у вас на сайте?', url: 'https://prokoleso.ua/shiny/letnie/' },
      { question: 'Какие размеры летних шин для  легковых автомобилей покупают больше всего на prokoleso.ua?', url: 'https://prokoleso.ua/shiny/letnie/' },
      { question: 'Какие типоразмеры зимних шин являются наиболее популярными ?', url: 'https://prokoleso.ua/shiny/zimnie/' },
      { question: 'Самые распространенные типоразмеры зимних шин', url: 'https://prokoleso.ua/shiny/zimnie/' },
      { question: 'Размеры зимних шин для самых популярных автомобилей', url: 'https://prokoleso.ua/shiny/zimnie/' },
      { question: 'Какие размеры зимних шин для  легковых автомобилей покупают больше всего у вас на сайте?', url: 'https://prokoleso.ua/shiny/zimnie/' },
      { question: 'Какие размеры зимних шин для  легковых автомобилей покупают больше всего на prokoleso.ua?', url: 'https://prokoleso.ua/shiny/zimnie/' },
      { question: 'Какие типоразмеры всесезонных шин являются наиболее популярными ?', url: 'https://prokoleso.ua/shiny/vsesezonie/' },
      { question: 'Какие размеры всесезонных шин для  легковых автомобилей покупают больше всего на prokoleso.ua?', url: 'https://prokoleso.ua/shiny/vsesezonie/' },
      { question: 'Какие размеры всесезонных шин для  легковых автомобилей покупают больше всего у вас на сайте?', url: 'https://prokoleso.ua/shiny/' },

    ],
    aliases: [
      { name: '175/70R13', alias: 'w-175/h-70/r-13' },
      { name: '175/70R14', alias: 'w-175/h-70/r-14' },
      { name: '185/70R14', alias: 'w-185/h-70/r-14' },
      { name: '175/65R14', alias: 'w-175/h-65/r-14' },
      { name: '185/65R14', alias: 'w-185/h-65/r-14' },
      { name: '185/60R14', alias: 'w-185/h-60/r-14' },
      { name: '185/65R15', alias: 'w-185/h-65/r-15' },
      { name: '195/65R15', alias: 'w-195/h-65/r-15' },
      { name: '205/65R15', alias: 'w-205/h-65/r-15' },
      { name: '185/60R15', alias: 'w-185/h-60/r-15' },
      { name: '195/60R15', alias: 'w-195/h-60/r-15' },
      { name: '215/70R16', alias: 'w-215/h-70/r-16' },
      { name: '205/65R16', alias: 'w-205/h-65/r-16' },
      { name: '215/65R16', alias: 'w-215/h-65/r-16' },
      { name: '205/60R16', alias: 'w-205/h-60/r-16' },
      { name: '215/60R16', alias: 'w-215/h-60/r-16' },
      { name: '205/55R16', alias: 'w-205/h-55/r-16' },
      { name: '215/55R16', alias: 'w-215/h-55/r-16' },
      { name: '225/65R17', alias: 'w-225/h-65/r-17' },
      { name: '265/65R17', alias: 'w-265/h-65/r-17' },
      { name: '215/60R17', alias: 'w-215/h-60/r-17' },
      { name: '225/60R17', alias: 'w-225/h-60/r-17' },
      { name: '215/55R17', alias: 'w-215/h-55/r-17' },
      { name: '225/55R17', alias: 'w-225/h-55/r-17' },
      { name: '225/50R17', alias: 'w-225/h-50/r-17' },
      { name: '225/45R17', alias: 'w-225/h-45/r-17' },
      { name: '225/60R18', alias: 'w-225/h-60/r-18' },
      { name: '235/60R18', alias: 'w-235/h-60/r-18' },
      { name: '225/55R18', alias: 'w-225/h-55/r-18' },
      { name: '235/55R18', alias: 'w-235/h-55/r-18' },

    ]
  }

  # ================================
  # Грузовые шины размеры
  SIZE_TRUCK = {
    questions: [
      { question: 'Какие размеры грузовых шин являются наиболее популярными  на вашем сайте?', url: 'https://prokoleso.ua/gruzovye-shiny/' },
      { question: 'Какие типоразмеры грузовых шин являются наиболее популярными ?', url: 'https://prokoleso.ua/gruzovye-shiny/' },
      { question: 'Самые распространенные типоразмеры грузовых шин', url: 'https://prokoleso.ua/gruzovye-shiny/' },
      { question: 'Размеры грузовых шин для самых популярных автомобилей', url: 'https://prokoleso.ua/gruzovye-shiny/' },
      { question: 'Какие размеры грузовых шин для самых популярных автомобилей покупают у вас на сайте?', url: 'https://prokoleso.ua/gruzovye-shiny/' },
      { question: 'Какие размеры грузовых шин для самых популярных автомобилей покупают prokoleso.ua?', url: 'https://prokoleso.ua/gruzovye-shiny/' },
    ],
    aliases: [
      { name: '295/80R22.5', alias: 'w-295/h-80/r-22.5' },
      { name: '315/80R22.5', alias: 'w-315/h-80/r-22.5' },
      { name: '385/65R22.5', alias: 'w-385/h-65/r-22.5' },
      { name: '315/70R22.5', alias: 'w-315/h-70/r-22.5' },
      { name: '385/55R22.5', alias: 'w-385/h-55/r-22.5' },
      { name: '425/65R22.5', alias: 'w-425/h-65/r-22.5' },
      { name: '445/65R22.5', alias: 'w-445/h-65/r-22.5' },
      { name: '215/75R17.5', alias: 'w-215/h-75/r-17.5' },
      { name: '225/70R19.5', alias: 'w-225/h-70/r-19.5' },
      { name: '235/75R17.5', alias: 'w-235/h-75/r-17.5' },
      { name: '245/70R19.5', alias: 'w-245/h-70/r-19.5' },
      { name: '265/70R19.5', alias: 'w-265/h-70/r-19.5' },
      { name: '275/70R22.5', alias: 'w-275/h-70/r-22.5' },
      { name: '285/70R19.5', alias: 'w-285/h-70/r-19.5' },

    ]
  }
  # Грузовые шины Диаметры
  DIAMETERS_TRUCK = {
    questions: [
      { question: 'Самые распространенные посадочные диаметры шин для грузовых автомобилей ', url: 'https://prokoleso.ua/gruzovye-shiny/' },
      { question: 'ТОП популярных посадочных диаметров для грузовых шин', url: 'https://prokoleso.ua/gruzovye-shiny/' },
      { question: 'ТОП популярных посадочных диаметров для грузовых шин, представленных на  prokoleso.ua', url: 'https://prokoleso.ua/gruzovye-shiny/' },
      { question: 'Какие диаметры шин для грузовых автомобилей покупают больше всего на prokoleso.ua?', url: 'https://prokoleso.ua/gruzovye-shiny/' },
      { question: 'Какие диаметры шин для грузовых автомобилей покупают больше всего на вашем сайте?', url: 'https://prokoleso.ua/gruzovye-shiny/' },

    ],
    aliases: [
      { name: 'R16', alias: 'r-16' },
      { name: 'R17.5', alias: 'r-17' },
      { name: 'R18', alias: 'r-18' },
      { name: 'R19.5', alias: 'r-19.5' },
      { name: 'R20', alias: 'r-20' },
      { name: 'R21', alias: 'r-21' },
      { name: 'R22.5', alias: 'r-22.5' }

    ]
  }
  # Грузовые шины бренды
  BRANDS_TRUCK = {
    questions: [
      { question: 'Топ производителей грузовых шин, представленных на сайте Prokoleso ', url: 'https://prokoleso.ua/gruzovye-shiny/' },
      { question: 'Кто входит в список лучших производителей грузовых шин?', url: 'https://prokoleso.ua/gruzovye-shiny/' },
      { question: 'Кто из известных шинных брендов представлен на сайте prokoleso.ua?', url: 'https://prokoleso.ua/gruzovye-shiny/' },
      { question: 'список лучших производителей грузовых шин', url: 'https://prokoleso.ua/gruzovye-shiny/' },
      { question: 'Лучшие производители грузовых шин ', url: 'https://prokoleso.ua/gruzovye-shiny/' },
      { question: 'Лучшие производители грузовых шин, представленные на сайте prokoleso.ua', url: 'https://prokoleso.ua/gruzovye-shiny/' },

    ],

    aliases: [
      {name: 'Aeolus',alias:'aeolus'},
      {name: 'Barum',alias:'barum'},
      {name: 'Bridgestone',alias:'bridgestone'},
      {name: 'Continental',alias:'continental'},
      {name: 'Crystal',alias:'crystal'},
      {name: 'Dongfeng',alias:'dongfeng'},
      {name: 'Hankook',alias:'hankook'},
      {name: 'Kumho',alias:'kumho'},
      {name: 'Marcher',alias:'marcher'},
      {name: 'Rosava',alias:'rosava'},
      {name: 'Satoya',alias:'satoya'},


    ]
  }


  # ================================
  # Диски - диаметры
  DIAMETERS_WHEELS = {
    questions: [
      { question: 'Самые распространенные  диаметры легкосплавных дисков для легковых автомобилей ', url: 'https://prokoleso.ua/diski/' },
      { question: 'ТОП популярных диаметров легкосплавных дисков для легковых автомобилей', url: 'https://prokoleso.ua/diski/' },
      { question: 'ТОП популярных диаметров легкосплавных дисков для легковых автомобилей, представленных на  prokoleso.ua', url: 'https://prokoleso.ua/diski/' },
      { question: 'Легкосплавные диски каких диаметров покупают больше всего на prokoleso.ua?', url: 'https://prokoleso.ua/diski/' },
      { question: 'Колесные диски каких диаметров больше всего покупают на вашем сайте?', url: 'https://prokoleso.ua/diski/' },
    ],
    aliases: [
      { name: 'R13', alias: 'r-13' },
      { name: 'R14', alias: 'r-14' },
      { name: 'R15', alias: 'r-15' },
      { name: 'R16', alias: 'r-16' },
      { name: 'R17', alias: 'r-17' },
      { name: 'R18', alias: 'r-18' },
      { name: 'R19', alias: 'r-19' },
      { name: 'R20', alias: 'r-20' },
      { name: 'R22', alias: 'r-22' }
    ]
  }
  BRANDS_WHEELS = {
    questions: [
      { question: 'Топ производителей легковых дисков, представленных на сайте Prokoleso ', url: 'https://prokoleso.ua/diski/' },
      { question: 'Кто входит в список лучших производителей дисков для легковых автомобилей?', url: 'https://prokoleso.ua/diski/' },
      { question: 'Кто из известных брендов представлен на сайте prokoleso.ua?', url: 'https://prokoleso.ua/diski/' },
      { question: 'список лучших производителей легковых дисков', url: 'https://prokoleso.ua/diski/' },
      { question: 'Лучшие производители легковых дисков ', url: 'https://prokoleso.ua/diski/' },
      { question: 'Лучшие производители легковых дисков, представленные на сайте prokoleso.ua', url: 'https://prokoleso.ua/diski/' },

    ],
    aliases: [
      {name: 'Alst ',alias:'alst '},
      {name: 'Дорожная Карта',alias:'dk'},
      {name: 'K7 ',alias:'k7 '},
      {name: 'Mak ',alias:'mak '},
      {name: 'MOMO Italy ',alias:'momo'},
      {name: 'Reds ',alias:'reds '},
      {name: 'Remain',alias:'remain'},
      {name: 'Replica',alias:'replica'},
      {name: 'Racing Wheels ',alias:'rw'},
      {name: 'Sportmax Racing',alias:'sportmaxracing'},
      {name: 'Techline ',alias:'techline '},
      {name: 'Trebl ',alias:'trebl '},
      {name: 'Vector ',alias:'vector '},
      {name: 'WSP Italy',alias:'wsp'},

    ]
  }


  # ================================
  # пусто
  TOP_MODEL = {
    questions: [

    ],
    aliases: [

    ]
  }

end