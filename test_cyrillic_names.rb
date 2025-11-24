#!/usr/bin/env ruby
# Тест проверки генерации только кириллических имен

require_relative 'config/environment'

class ReviewServiceTest
  include ServiceReviewOut
end

puts "="*80
puts "ТЕСТ: Проверка генерации только кириллических имен"
puts "="*80
puts

service = ReviewServiceTest.new

# Регулярное выражение для проверки наличия латинских букв
latin_pattern = /[a-zA-Z]/

errors = []
total_tests = 100

puts "Генерируем #{total_tests} имен для проверки..."
puts

# Проверяем русский язык
puts "Русский язык (ru):"
puts "-"*80

male_names_ru = []
female_names_ru = []

25.times do
  # Мужские имена
  name = service.send(:get_author_name, "ru", "мужчина")
  male_names_ru << name
  if name =~ latin_pattern
    errors << "Мужское (RU): #{name} - содержит латиницу!"
  end

  # Женские имена
  name = service.send(:get_author_name, "ru", "женщина")
  female_names_ru << name
  if name =~ latin_pattern
    errors << "Женское (RU): #{name} - содержит латиницу!"
  end
end

puts "Мужские имена (примеры):"
male_names_ru.first(10).each { |name| puts "  - #{name}" }
puts
puts "Женские имена (примеры):"
female_names_ru.first(10).each { |name| puts "  - #{name}" }
puts

# Проверяем украинский язык
puts "Украинский язык (ua):"
puts "-"*80

male_names_ua = []
female_names_ua = []

25.times do
  # Мужские имена
  name = service.send(:get_author_name, "ua", "мужчина")
  male_names_ua << name
  if name =~ latin_pattern
    errors << "Мужское (UA): #{name} - содержит латиницу!"
  end

  # Женские имена
  name = service.send(:get_author_name, "ua", "женщина")
  female_names_ua << name
  if name =~ latin_pattern
    errors << "Женское (UA): #{name} - содержит латиницу!"
  end
end

puts "Мужские имена (примеры):"
male_names_ua.first(10).each { |name| puts "  - #{name}" }
puts
puts "Женские имена (примеры):"
female_names_ua.first(10).each { |name| puts "  - #{name}" }
puts

# Результаты
puts "="*80
puts "РЕЗУЛЬТАТЫ ТЕСТА"
puts "="*80
puts

if errors.empty?
  puts "✓ ВСЕ ТЕСТЫ ПРОЙДЕНЫ УСПЕШНО!"
  puts "✓ Все #{total_tests} имен содержат только кириллицу"
  puts "✓ Латинские символы не обнаружены"
else
  puts "✗ ОБНАРУЖЕНЫ ОШИБКИ:"
  puts
  errors.each { |error| puts "  #{error}" }
  puts
  puts "Всего ошибок: #{errors.size} из #{total_tests}"
end

puts

# Проверяем разнообразие форматов
puts "Проверка форматов имен:"
puts "-"*80

all_names = male_names_ru + female_names_ru + male_names_ua + female_names_ua

# С отчеством
with_patronymic = all_names.select { |name| name.split.size == 2 && !name.match(/\d/) }
# С датой рождения
with_date = all_names.select { |name| name.match(/\d/) }
# Строчные
lowercase = all_names.select { |name| name == name.downcase }
# Обычные
normal = all_names - with_patronymic - with_date - lowercase

puts "Обычные имена:           #{normal.size} (#{(normal.size.to_f / all_names.size * 100).round}%)"
puts "С отчеством:             #{with_patronymic.size} (#{(with_patronymic.size.to_f / all_names.size * 100).round}%)"
puts "С датой рождения:        #{with_date.size} (#{(with_date.size.to_f / all_names.size * 100).round}%)"
puts "В нижнем регистре:       #{lowercase.size} (#{(lowercase.size.to_f / all_names.size * 100).round}%)"

puts
puts "Примеры форматов:"
puts "  Обычное: #{normal.first}" if normal.any?
puts "  С отчеством: #{with_patronymic.first}" if with_patronymic.any?
puts "  С датой: #{with_date.first}" if with_date.any?
puts "  Нижний регистр: #{lowercase.first}" if lowercase.any?

puts
puts "="*80
