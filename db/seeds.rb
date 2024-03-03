require 'roo'

Diameter.delete_all
Brand.delete_all
City.delete_all
CityUrl.delete_all
Season.delete_all
Addon.delete_all
Size.delete_all
TyresFaq.delete_all

DiameterCopy.delete_all
BrandCopy.delete_all
CityCopy.delete_all
CityUrlCopy.delete_all
SeasonCopy.delete_all
AddonCopy.delete_all
SizeCopy.delete_all
TyresFaqCopy.delete_all



diameter_array = ["12", '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23',
                  '12c','13c','14c','15c','16c','17c']
diameter_array.each do |el|
  Diameter.create(name: el, url: "r-#{el.downcase}")
end

season_array = [
                {name: "зимние", url: 'zimnie'}, {name: "зима", url: 'zimnie'},
                {name: "зимові", url: 'zimnie'}, {name: "на зиму", url: 'zimnie'},
                {name: "шипованные", url: 'zimnie'}, {name: "шиповані", url: 'zimnie'},
                {name: "не шипованные", url: 'zimnie'}, {name: "нешиповані", url: 'zimnie'},
                {name: "с шипами", url: 'zimnie'}, {name: "липучка", url: 'zimnie'},
                {name: "з шипами", url: 'zimnie'}, {name: "ліпучка", url: 'zimnie'},
                {name: "для снега", url: 'zimnie'}, {name: "для снігу", url: 'zimnie'},

                {name: "всесезонные", url: 'vsesezonie'},  {name: "всесезонні", url: 'vsesezonie'},
                {name: "универсальные", url: 'vsesezonie'},  {name: "всепогодные", url: 'vsesezonie'},
                {name: "універсальні", url: 'vsesezonie'},  {name: "всепогодні", url: 'vsesezonie'},

                {name: "летние", url: 'letnie'},  {name: "літні", url: 'letnie'},
                {name: "літо", url: 'letnie'}, {name: "на літо", url: 'letnie'},
                {name: "для дождя", url: 'letnie'}, {name: "для дощу", url: 'letnie'},
                {name: "дождевая", url: 'letnie'}, {name: "дощева", url: 'letnie'},
                {name: "лето", url: 'letnie'}, {name: "на лето", url: 'letnie'}]

season_array.each do |el|
  Season.create(name: el[:name], url: el[:url].downcase)
end

#===========Заменить==============================
# CityUrl
# city_array = [{name: "киев", url: 'shiny-kiev'},
#               {name: "в днепре", url: 'shiny-dnepr'},
#               {name: "одесса", url: 'shiny-odessa'},
#               {name: "львов", url: 'shiny-lvov'}]
# city_array.each do |el|
#   CityUrl.create(name: el[:name], url: el[:url].downcase)
# end


excel_file = "lib/cities_url.xlsx"
excel = Roo::Excelx.new(excel_file)

4.times do |i|
  excel.each_row_streaming(pad_cells: true) do |row|
    name = row[i+1]&.value
    url = row[0]&.value
    CityUrl.create(name: name, url: url) if name.present?
  end
end



# City
# city_array = [{name: "киев", url: ''},
#                {name: "харьков", url: ''}, {name: "в днепре", url: ''},
#                {name: "одесса", url: ''}, {name: "житомир", url: ''},
#                {name: "в кривом рогу", url: ''}, {name: "львов", url: ''}]
# city_array.each do |el|
#   City.create(name: el[:name], url: el[:url].downcase)
# end

excel_file = "lib/cities.xlsx"
excel = Roo::Excelx.new(excel_file)

4.times do |i|
  excel.each_row_streaming(pad_cells: true) do |row|
    name = row[i]&.value
    url = ''
    City.create(name: name, url: url) if name.present?
  end
end






# =========================================================
# Загрузка размеров
# size_array = [{ww: "175", hh: '70', rr:'13', url: 'w-175/h-70/r-13'},
#               {ww: "175", hh: '65', rr:'14', url: 'w-175/h-65/r-14'}
# ]
# size_array.each do |el|
#   Size.create(ww: el[:ww], hh: el[:hh], rr: el[:rr],url: el[:url].downcase)
# end


excel_file = "lib/sizes_link.xlsx"
excel = Roo::Excelx.new(excel_file)

excel.each_row_streaming(pad_cells: true) do |row|
  url = row[4]&.value
  Size.create(ww: row[1]&.value, hh: row[2]&.value, rr: row[3]&.value, url: url) if url.present?
end

# =========================================================
# Загрузка Брендов
# brands_array = [
#   "Michelin", "Bridgestone", "Goodyear", "Continental", "Pirelli"
# ]
#
# brands_array.each do |el|
#   Brand.create(name: el, url: el.downcase)
# end

excel_file = "lib/brands.xlsx"
excel = Roo::Excelx.new(excel_file)

3.times do |i|
  excel.each_row_streaming(pad_cells: true) do |row|
    name = row[i+1]&.value
    url = row[0]&.value
    Brand.create(name: name, url: url) if name.present?
  end
end

# attribute
# addon_array = [{name: "шины", url: ''},{name: "шына", url: ''}, {name: "шыны", url: ''},]
# addon_array.each do |el|
#   Addon.create(name: el[:name], url: el[:url].downcase)
# end

excel_file = "lib/addons.xlsx"
excel = Roo::Excelx.new(excel_file)

excel.each_row_streaming(pad_cells: true) do |row|
  name = row[0]&.value
  Addon.create(name: name, url: '') if name.present?
end

# Заполнение таблицы с вопросам по легковым шинам
excel_file = "lib/tires_FAQs.xlsx"
excel = Roo::Excelx.new(excel_file)

excel.each_row_streaming(pad_cells: true) do |row|
  question = row[0]&.value
  theme = row[1]&.value
  TyresFaq.create(question: question, theme: theme) if question.present?
end