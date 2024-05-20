require 'active_record'

# Загружаем конфигурацию базы данных
database_config = YAML.load(File.read('config/database.yml'))

# Получаем настройки подключения для среды development
db_config = database_config['development']

# Устанавливаем соединение с базой данных
ActiveRecord::Base.establish_connection(db_config)


def upload
  excel_file = "lib/sizes_link.xlsx"
  excel = Roo::Excelx.new(excel_file)

  # Получаем объект подключения к базе данных
  connection = ActiveRecord::Base.connection

  excel.each_row_streaming(pad_cells: true) do |row|
    puts row
    connection.execute("
      INSERT INTO sizes (ww, hh, rr, url, created_at, updated_at)
      VALUES ('#{row[1].value}', '#{row[2].value}', '#{row[3].value}', '#{row[3].value}', '#{Time.now}', '#{Time.now}')
    ")
  end
end

upload
