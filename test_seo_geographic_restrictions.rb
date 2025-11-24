#!/usr/bin/env ruby
# Тест проверки запрета российских топонимов в SEO текстах

require_relative 'config/environment'

puts "="*80
puts "ТЕСТ: Проверка запрета российских топонимов в SEO генераторах"
puts "="*80
puts

# Тест 1: SeoTextGenerator (описания моделей шин)
puts "ТЕСТ 1: SeoTextGenerator - генерация SEO текстов для шин"
puts "-"*80
puts

tire_params_ru = {
  tire_description: "Зимние шины Michelin X-Ice для легковых автомобилей",
  brand: "Michelin",
  model: "X-Ice",
  season: "зимние",
  language: "ru",
  size: "215/55R17",
  product_id: 12345,
  load_index: "94",
  speed_index: "H",
  links: []
}

tire_params_ua = tire_params_ru.merge(language: "ua", season: "зимові")

puts "Русский язык:"
tire_generator_ru = SeoTextGenerator.new(tire_params_ru)
tire_prompt_ru = tire_generator_ru.send(:build_generation_prompt)

puts "Длина промпта: #{tire_prompt_ru.length} символов"
puts

# Проверяем наличие ключевых слов
checks_ru = {
  "Содержит 'КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО'" => tire_prompt_ru.include?("КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО"),
  "Упоминает 'Москва'" => tire_prompt_ru.include?("Москва"),
  "Упоминает 'Россия'" => tire_prompt_ru.include?("Россия"),
  "Упоминает 'российский'" => tire_prompt_ru.include?("российский"),
  "Содержит 'РАЗРЕШЕНО'" => tire_prompt_ru.include?("РАЗРЕШЕНО"),
  "Упоминает 'Киев'" => tire_prompt_ru.include?("Киев"),
  "Упоминает 'Украину'" => tire_prompt_ru.include?("Украину")
}

all_checks_passed = true
checks_ru.each do |check_name, result|
  status = result ? "✓" : "✗"
  puts "#{status} #{check_name}"
  all_checks_passed = false unless result
end

puts
puts "Украинский язык:"
tire_generator_ua = SeoTextGenerator.new(tire_params_ua)
tire_prompt_ua = tire_generator_ua.send(:build_generation_prompt)

puts "Длина промпта: #{tire_prompt_ua.length} символов"
puts

checks_ua = {
  "Содержит 'КАТЕГОРИЧНО ЗАБОРОНЕНО'" => tire_prompt_ua.include?("КАТЕГОРИЧНО ЗАБОРОНЕНО"),
  "Упоминает 'Москва'" => tire_prompt_ua.include?("Москва"),
  "Упоминает 'Росія'" => tire_prompt_ua.include?("Росія"),
  "Упоминает 'російський'" => tire_prompt_ua.include?("російський"),
  "Содержит 'ДОЗВОЛЕНО'" => tire_prompt_ua.include?("ДОЗВОЛЕНО"),
  "Упоминает 'Київ'" => tire_prompt_ua.include?("Київ"),
  "Упоминает 'Україну'" => tire_prompt_ua.include?("Україну")
}

checks_ua.each do |check_name, result|
  status = result ? "✓" : "✗"
  puts "#{status} #{check_name}"
  all_checks_passed = false unless result
end

puts
if all_checks_passed
  puts "✓ SeoTextGenerator: ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ"
else
  puts "✗ SeoTextGenerator: НЕКОТОРЫЕ ПРОВЕРКИ НЕ ПРОШЛИ"
end

puts
puts "="*80
puts "ТЕСТ 2: CarSeoTextGenerator - генерация SEO текстов для автомобилей"
puts "-"*80
puts

car_params_ru = {
  brand: "Toyota",
  model: "Camry",
  language: "ru",
  typical_sizes: ["215/55R17", "225/45R18"],
  generation: "XV70",
  production_years: "2017-2021",
  body_type: "седан",
  car_class: "D"
}

car_params_ua = car_params_ru.merge(language: "ua")

puts "Русский язык:"
car_generator_ru = CarSeoTextGenerator.new(car_params_ru)
car_prompt_ru = car_generator_ru.send(:build_prompt)

puts "Длина промпта: #{car_prompt_ru.length} символов"
puts

car_checks_ru = {
  "Содержит 'КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО'" => car_prompt_ru.include?("КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО"),
  "Упоминает 'Москва'" => car_prompt_ru.include?("Москва"),
  "Упоминает 'Россия'" => car_prompt_ru.include?("Россия"),
  "Упоминает 'российский'" => car_prompt_ru.include?("российский"),
  "Содержит 'РАЗРЕШЕНО'" => car_prompt_ru.include?("РАЗРЕШЕНО"),
  "Упоминает 'Киев'" => car_prompt_ru.include?("Киев")
}

car_checks_ru.each do |check_name, result|
  status = result ? "✓" : "✗"
  puts "#{status} #{check_name}"
  all_checks_passed = false unless result
end

puts
puts "Украинский язык:"
car_generator_ua = CarSeoTextGenerator.new(car_params_ua)
car_prompt_ua = car_generator_ua.send(:build_prompt)

puts "Длина промпта: #{car_prompt_ua.length} символов"
puts

car_checks_ua = {
  "Содержит 'КАТЕГОРИЧНО ЗАБОРОНЕНО'" => car_prompt_ua.include?("КАТЕГОРИЧНО ЗАБОРОНЕНО"),
  "Упоминает 'Москва'" => car_prompt_ua.include?("Москва"),
  "Упоминает 'Росія'" => car_prompt_ua.include?("Росія"),
  "Содержит 'ДОЗВОЛЕНО'" => car_prompt_ua.include?("ДОЗВОЛЕНО"),
  "Упоминает 'Київ'" => car_prompt_ua.include?("Київ")
}

car_checks_ua.each do |check_name, result|
  status = result ? "✓" : "✗"
  puts "#{status} #{check_name}"
  all_checks_passed = false unless result
end

puts
if all_checks_passed
  puts "✓ CarSeoTextGenerator: ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ"
else
  puts "✗ CarSeoTextGenerator: НЕКОТОРЫЕ ПРОВЕРКИ НЕ ПРОШЛИ"
end

puts
puts "="*80
puts "РЕЗЮМЕ"
puts "="*80
puts

if all_checks_passed
  puts "✓✓✓ ВСЕ ТЕСТЫ УСПЕШНО ПРОЙДЕНЫ ✓✓✓"
  puts
  puts "Географические ограничения добавлены в:"
  puts "  1. SeoTextGenerator (SEO тексты для моделей шин)"
  puts "     - Русский язык: /api/v1/generate_seo_text?language=ru"
  puts "     - Украинский язык: /api/v1/generate_seo_text?language=ua"
  puts
  puts "  2. CarSeoTextGenerator (SEO тексты для автомобилей)"
  puts "     - Русский язык: app/services/car_seo_text_generator.rb"
  puts "     - Украинский язык: app/services/car_seo_text_generator.rb"
  puts
  puts "Ограничения:"
  puts "  ✓ ЗАПРЕЩЕНО: Москва, Санкт-Петербург, Россия, российский"
  puts "  ✓ ЗАПРЕЩЕНО: Любые другие российские географические названия"
  puts "  ✓ РАЗРЕШЕНО: Только украинские города (Киев, Харьков, Одесса, Львов, Днепр)"
  puts "  ✓ Инструкции на русском и украинском языках"
else
  puts "✗✗✗ НЕКОТОРЫЕ ТЕСТЫ НЕ ПРОШЛИ ✗✗✗"
  puts "Проверьте логи выше для деталей"
end

puts
puts "="*80
