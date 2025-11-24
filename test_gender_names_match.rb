#!/usr/bin/env ruby
# Тест проверки соответствия имен и пола

require_relative 'config/environment'

class ReviewServiceTest
  include ServiceReviewOut
end

puts "="*80
puts "ТЕСТ: Проверка соответствия имен и пола (гендера)"
puts "="*80
puts

service = ReviewServiceTest.new

# Загружаем списки имен из констант
male_names_ru = MALE_NAMES[:names_ru] + MALE_NAMES[:diminutive_names_ru]
female_names_ru = FEMALE_NAMES[:names_ru] + FEMALE_NAMES[:diminutive_names_ru]

male_names_ua = MALE_NAMES[:names_ua] + MALE_NAMES[:diminutive_names_ua]
female_names_ua = FEMALE_NAMES[:names_ua] + FEMALE_NAMES[:diminutive_names_ua]

errors = []
total_tests = 200

puts "Генерируем #{total_tests} имен (по 50 для каждой комбинации пола/языка)..."
puts

# Тест 1: Русский язык, мужчины
puts "ТЕСТ 1: Русский язык, мужской пол"
puts "-"*80

generated_male_ru = []
50.times do
  name = service.send(:get_author_name, "ru", "мужчина")
  generated_male_ru << name

  # Убираем отчество и дату рождения для проверки базового имени
  base_name = name.split.first.gsub(/\d+/, '')

  # Проверяем, что базовое имя есть в мужском списке
  unless male_names_ru.any? { |male_name| male_name.downcase == base_name.downcase }
    # Проверяем, не попало ли женское имя
    if female_names_ru.any? { |female_name| female_name.downcase == base_name.downcase }
      errors << "ОШИБКА: Для мужчины сгенерировано женское имя: #{name} (RU)"
    end
  end
end

puts "Примеры сгенерированных мужских имен:"
generated_male_ru.first(10).each { |name| puts "  - #{name}" }
puts

# Тест 2: Русский язык, женщины
puts "ТЕСТ 2: Русский язык, женский пол"
puts "-"*80

generated_female_ru = []
50.times do
  name = service.send(:get_author_name, "ru", "женщина")
  generated_female_ru << name

  base_name = name.split.first.gsub(/\d+/, '')

  unless female_names_ru.any? { |female_name| female_name.downcase == base_name.downcase }
    if male_names_ru.any? { |male_name| male_name.downcase == base_name.downcase }
      errors << "ОШИБКА: Для женщины сгенерировано мужское имя: #{name} (RU)"
    end
  end
end

puts "Примеры сгенерированных женских имен:"
generated_female_ru.first(10).each { |name| puts "  - #{name}" }
puts

# Тест 3: Украинский язык, мужчины
puts "ТЕСТ 3: Украинский язык, мужской пол"
puts "-"*80

generated_male_ua = []
50.times do
  name = service.send(:get_author_name, "ua", "мужчина")
  generated_male_ua << name

  base_name = name.split.first.gsub(/\d+/, '')

  unless male_names_ua.any? { |male_name| male_name.downcase == base_name.downcase }
    if female_names_ua.any? { |female_name| female_name.downcase == base_name.downcase }
      errors << "ОШИБКА: Для мужчины сгенерировано женское имя: #{name} (UA)"
    end
  end
end

puts "Примеры сгенерированных мужских имен:"
generated_male_ua.first(10).each { |name| puts "  - #{name}" }
puts

# Тест 4: Украинский язык, женщины
puts "ТЕСТ 4: Украинский язык, женский пол"
puts "-"*80

generated_female_ua = []
50.times do
  name = service.send(:get_author_name, "ua", "женщина")
  generated_female_ua << name

  base_name = name.split.first.gsub(/\d+/, '')

  unless female_names_ua.any? { |female_name| female_name.downcase == base_name.downcase }
    if male_names_ua.any? { |male_name| male_name.downcase == base_name.downcase }
      errors << "ОШИБКА: Для женщины сгенерировано мужское имя: #{name} (UA)"
    end
  end
end

puts "Примеры сгенерированных женских имен:"
generated_female_ua.first(10).each { |name| puts "  - #{name}" }
puts

# Результаты
puts "="*80
puts "РЕЗУЛЬТАТЫ ТЕСТА"
puts "="*80
puts

if errors.empty?
  puts "✓ ВСЕ ТЕСТЫ ПРОЙДЕНЫ УСПЕШНО!"
  puts "✓ Все #{total_tests} имен соответствуют указанному полу"
  puts "✓ Ошибок соответствия не обнаружено"
  puts
  puts "Проверено:"
  puts "  - Русский язык, мужчины: 50 имен ✓"
  puts "  - Русский язык, женщины: 50 имен ✓"
  puts "  - Украинский язык, мужчины: 50 имен ✓"
  puts "  - Украинский язык, женщины: 50 имен ✓"
else
  puts "✗ ОБНАРУЖЕНЫ ОШИБКИ СООТВЕТСТВИЯ:"
  puts
  errors.each { |error| puts "  #{error}" }
  puts
  puts "Всего ошибок: #{errors.size} из #{total_tests}"
end

puts
puts "="*80
puts "Дополнительная проверка: отчества соответствуют полу"
puts "="*80
puts

# Проверка отчеств
male_patronymics_ru = MALE_PATRNYMICS[:patronymics_ru]
female_patronymics_ru = FEMALE_PATRNYMICS[:patronymics_ru]

with_patronymic_male = generated_male_ru.select { |n| n.split.size == 2 && !n.match(/\d/) }
with_patronymic_female = generated_female_ru.select { |n| n.split.size == 2 && !n.match(/\d/) }

puts "\nМужские имена с отчествами (примеры):"
with_patronymic_male.first(5).each { |name| puts "  - #{name}" }

puts "\nЖенские имена с отчествами (примеры):"
with_patronymic_female.first(5).each { |name| puts "  - #{name}" }

patronymic_errors = []

with_patronymic_male.each do |full_name|
  patronymic = full_name.split.last
  unless male_patronymics_ru.include?(patronymic)
    if female_patronymics_ru.include?(patronymic)
      patronymic_errors << "Мужское имя с женским отчеством: #{full_name}"
    end
  end
end

with_patronymic_female.each do |full_name|
  patronymic = full_name.split.last
  unless female_patronymics_ru.include?(patronymic)
    if male_patronymics_ru.include?(patronymic)
      patronymic_errors << "Женское имя с мужским отчеством: #{full_name}"
    end
  end
end

puts

if patronymic_errors.empty?
  puts "✓ Отчества соответствуют полу"
  puts "  Проверено мужских имен с отчествами: #{with_patronymic_male.size}"
  puts "  Проверено женских имен с отчествами: #{with_patronymic_female.size}"
else
  puts "✗ Найдены ошибки в отчествах:"
  patronymic_errors.each { |error| puts "  #{error}" }
end

puts
puts "="*80
