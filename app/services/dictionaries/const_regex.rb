SEARCH_SIZE_1 = /(?<=^|\s)\d{3}([ \/.-xXхХ]*| на )\d{2}([ \/.-xXхХ]*| на )(|[ rRpPрР])([ \/.-xXхХ]*)\d{2}([.,]\d{1})?[ \/.-]*[ cCсС]*/
SEARCH_SIZE_2 = /(?<=^|\s)(на |)[ rRpPрР]\d{2}([.,]\d{1})?[ \/.-xXхХ]*[ cCсС]*([ \/.-xXхХ]*| на )\d{3}([ \/.-xXхХ]*| на )\d{2}/
SEARCH_SIZE_3 = /(?<=^|\s)(\d{2}(|(.|,)00)R\d{2})/
SEARCH_SIZE_4 = /(?<=^|\s)(R\d{2})/
SEARCH_SIZE_DISKI_1 = /((|j)\d\.\d(|j)(|\s)(|r)\d{2}(|\s)(|r)(|pcd)\d(x|х|\/|)\d{2,3}(\.\d|))/i
SEARCH_SIZE_DISKI_2  = /(|pcd)\d{1,2}(x|х|\/|)\d{2,3}(\.\d|)(\s|)(|на\s)(j|r|)\d{1,3}(|\.\d{1,2})(j|r|)(x|х|)\d{1,3}(\.\d{1,2}|)/i

TIRE_POPULAR_SIZES = {
  "13": ["175/60 R13", "155/65 R13", "155/70 R13", "175/70 R13", "185/60 R13", "185/70 R13", "165/65 R13", "165/70 R13"],
  "14": ["155/65 R14", "165/60 R14", "165/65 R14", "165/70 R14", "175/60 R14", "175/65 R14", "175/70 R14", "185/60 R14", "185/65 R14", "185/70 R14"],
  "15": ["175/60 R15", "175/65 R15", "185/55 R15", "185/60 R15", "185/65 R15", "195/50 R15", "195/55 R15", "195/60 R15", "195/65 R15", "205/55 R15", "205/60 R15", "205/65 R15", "205/70 R15", "215/55 R15", "195/70 R15C", "195/70 R15c", "225/70 R15C", "225/70 R15c"],
  "16": ["185/55 R16", "195/55 R16", "195/60 R16", "205/50 R16", "205/55 R16", "205/60 R16", "205/65 R16", "215/55 R16", "215/60 R16", "215/65 R16", "215/70 R16", "225/55 R16", "225/60 R16", "235/60 R16", "245/70 R16", "205/65 R16C", "205/65 R16c", "215/65 R16C", "215/65 R16c"],
  "17": ["205/50 R17", "205/55 R17", "215/45 R17", "215/50 R17", "215/55 R17", "215/60 R17", "215/65 R17", "225/45 R17", "225/50 R17", "225/55 R17", "225/60 R17", "225/65 R17", "235/60 R17", "235/45 R17", "235/55 R17", "235/60 R17", "235/65 R17", "255/65 R17", "265/65 R17"],
  "18": ["215/55 R18", "225/45 R18", "225/50 R18", "225/55 R18", "225/60 R18", "235/45 R18", "235/50 R18", "235/55 R18", "235/60 R18", "235/65 R18", "245/40 R18", "245/45 R18", "245/60 R18", "255/55 R18", "255/60 R18", "265/60 R18", "285/60 R18"],
  "19": ["225/45 R19", "225/55 R19", "235/35 R19", "235/50 R19", "235/55 R19", "245/45 R19", "245/55 R19", "255/45 R19", "255/50 R19", "255/55 R19", "265/50 R19"],
  "20": ["235/55 R20", "245/50 R20", "255/45 R20", "255/50 R20", "265/50 R20", "275/40 R20", "275/45 R20", "275/50 R20", "285/45 R20", "285/50 R20"],
  "21": ["275/45 R21", "285/45 R21"],
  # "22": ["265/30 R22", "265/35 R22", "275/25 R22", "275/30 R22", "285/25 R22", "285/30 R22", "295/25 R22", "295/30 R22", "305/25 R22", "305/30 R22", "315/25 R22", "325/25 R22", "335/25 R22"]
}

AXIS_PRICEP = [
  "215/75R17.5",
  "235/75R17.5",
  "245/70R17.5",
  "245/70R19.5",
  "385/55R19.5",
  "435/50R19.5",
  "445/45R19.5",
  "385/55R22.5",
  "385/65R22.5",
  "445/65R22.5"
]

MARKS = {
  "литец" => "литые диски",
  "литецы" => "литые диски",
  "литецов" => "литых дисков",
  "литеца" => "литых дисков",
  "литца" => "литых дисков",
  "литецами" => "литыми дисками",
  "литецкие" => "литые"
}

AUTO_MANUFACTURES = ["Toyota", "Volkswagen", "Ford", "Chevrolet", "Honda", "Nissan",
                     "Mercedes", "BMW", "Audi", "Hyundai", "Kia", "Volvo", "Fiat",
                     "Renault", "Peugeot", "Mazda", "Subaru", "Jeep", "Tesla", "Lexus",
                     "Cadillac", "Mitsubishi", "Suzuki", "Land Rover", "Jaguar",
                     "Ferrari", "Porsche", "Lamborghini", "Maserati", "Bugatti", "McLaren", "Aston Martin",
                     "Geely", "BYD", "Great Wall Motors", "Changan", "SAIC Motor Corporation", "General Motors",
                     # дополнительные расширения:
                     "Automobile", "Motor", "Corporation", "Rover"
]
