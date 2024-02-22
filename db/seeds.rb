# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

Diameter.delete_all
Brand.delete_all
City.delete_all
Season.delete_all
Addon.delete_all
Size.delete_all

DiameterCopy.delete_all
BrandCopy.delete_all
CityCopy.delete_all
SeasonCopy.delete_all
AddonCopy.delete_all
SizeCopy.delete_all

brands_array = [
  "Michelin", "Bridgestone", "Goodyear", "Continental", "Pirelli",
  "Dunlop", "Yokohama", "Firestone", "Hankook", "Toyo", "Kumho", "Falken",
  "Nokian", "Cooper", "Sumitomo", "MRF", "Apollo", "Maxxis", "Ceat"
]

brands_array.each do |el|
  Brand.create(name: el, url: el.downcase)
end

diameter_array = ["12", '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '12c','13c','14c','15c','16c','17c']
diameter_array.each do |el|
  Diameter.create(name: el, url: "r-#{el.downcase}")
end

season_array = [{name: "летние", url: 'letnie'},
                {name: "зимние", url: 'zimnie'}, {name: "зима", url: 'zimnie'},
                {name: "лето", url: 'letnie'}, {name: "на лето", url: 'letnie'}]
season_array.each do |el|
  Season.create(name: el[:name], url: el[:url].downcase)
end

addon_array = [{name: "шины", url: ''},
                {name: "шына", url: ''}, {name: "шыны", url: ''},
               {name: "колеса", url: ''}, {name: "покрышки", url: ''},
                {name: "резина", url: ''}, {name: "колесо", url: ''}]
addon_array.each do |el|
  Addon.create(name: el[:name], url: el[:url].downcase)
end


# City
city_array = [{name: "киев", url: ''},
               {name: "харьков", url: ''}, {name: "в днепре", url: ''},
               {name: "одесса", url: ''}, {name: "житомир", url: ''},
               {name: "в кривом рогу", url: ''}, {name: "львов", url: ''}]
city_array.each do |el|
  City.create(name: el[:name], url: el[:url].downcase)
end

size_array = [{ww: "175", hh: '70', rr:'13', url: 'w-175/h-70/r-13'},
              {ww: "185", hh: '65', rr:'14', url: 'w-185/h-65/r-14'},
              {ww: "195", hh: '55', rr:'15', url: 'w-195/h-55/r-15'},
              {ww: "205", hh: '55', rr:'16', url: 'w-205/h-55/r-16'},
              {ww: "215", hh: '55', rr:'17', url: 'w-215/h-55/r-17'},
              {ww: "205", hh: '65', rr:'15', url: 'w-205/h-65/r-15'},
              {ww: "175", hh: '65', rr:'14', url: 'w-175/h-65/r-14'}
]
size_array.each do |el|
  Size.create(ww: el[:ww], hh: el[:hh], rr: el[:rr],url: el[:url].downcase)
end