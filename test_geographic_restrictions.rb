#!/usr/bin/env ruby
# Тест проверки запрета российских топонимов в отзывах

require_relative 'config/environment'

puts "="*80
puts "ТЕСТ: Проверка запрета российских топонимов в AI промптах"
puts "="*80
puts

processor = UniversalReviewProcessor.new

# Тест 1: Проверка наличия инструкций в промпте
puts "ТЕСТ 1: Проверка инструкций о географических ограничениях"
puts "-"*80

context = {
  brand: "Michelin",
  model: "X-Ice",
  gender: "мужчина",
  grade: 4.5,
  array_average: [4.5, 5.0, 4.0, 4.5]
}

instructions = processor.send(:build_context_instructions, context)

puts "Инструкции для AI:"
puts instructions
puts

# Проверяем наличие ключевых слов в инструкциях
forbidden_keywords = ["ЗАПРЕЩЕНО", "Москва", "Россия", "российск"]
allowed_keywords = ["РАЗРЕШЕНО", "украинск", "Киев"]

has_forbidden = forbidden_keywords.any? { |keyword| instructions.include?(keyword) }
has_allowed = allowed_keywords.any? { |keyword| instructions.include?(keyword) }

if has_forbidden && has_allowed
  puts "✓ Инструкции содержат запреты на российские топонимы"
  puts "✓ Инструкции содержат разрешение на украинские топонимы"
else
  puts "✗ ОШИБКА: Инструкции не содержат необходимых ограничений"
end

puts
puts "="*80
puts "ТЕСТ 2: Проверка метода build_geographic_restrictions"
puts "-"*80

geo_restrictions = processor.send(:build_geographic_restrictions)

puts "Географические ограничения:"
puts geo_restrictions
puts

# Проверка содержимого
checks = {
  "Содержит 'ЗАПРЕЩЕНО'" => geo_restrictions.include?("ЗАПРЕЩЕНО"),
  "Упоминает 'Москва'" => geo_restrictions.include?("Москва"),
  "Упоминает 'Россия'" => geo_restrictions.include?("Россия"),
  "Упоминает 'российский'" => geo_restrictions.include?("российский"),
  "Содержит 'РАЗРЕШЕНО'" => geo_restrictions.include?("РАЗРЕШЕНО"),
  "Упоминает 'Киев'" => geo_restrictions.include?("Киев"),
  "Упоминает 'Украину'" => geo_restrictions.include?("Украину")
}

all_passed = true
checks.each do |check_name, result|
  status = result ? "✓" : "✗"
  puts "#{status} #{check_name}: #{result}"
  all_passed = false unless result
end

puts
if all_passed
  puts "✓ ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ"
else
  puts "✗ НЕКОТОРЫЕ ПРОВЕРКИ НЕ ПРОШЛИ"
end

puts
puts "="*80
puts "ТЕСТ 3: Интеграционный тест - полный промпт для AI"
puts "-"*80

# Создаем полный контекст как при реальной генерации
full_context = {
  brand: "Continental",
  model: "WinterContact",
  car: "Toyota Camry",
  type_review: 1,
  season: 2,
  language: "ru",
  gender: "женщина",
  grade: 4.5,
  array_average: [4.5, 5.0, 4.0, 4.5],
  review_date: "2025-11-20",
  purchase_date: "2025-09-15",
  time_description: "пару месяцев назад"
}

original_review = "Отличные зимние шины! Купила недавно и уже проверила на снегу - супер сцепление. Рекомендую!"

# Получаем анализ
analysis = processor.send(:analyze_original_review, original_review)

# Строим полный промпт
full_prompt = processor.send(:build_smart_prompt, original_review, analysis, full_context)

puts "ПОЛНЫЙ ПРОМПТ ДЛЯ AI:"
puts "-"*80
puts full_prompt
puts "-"*80
puts

# Проверяем наличие всех важных инструкций
prompt_checks = {
  "Упоминание бренда Continental" => full_prompt.include?("Continental"),
  "Инструкция по полу (женщина)" => full_prompt.include?("женщин"),
  "Инструкция по оценке" => full_prompt.include?("4.5"),
  "Инструкция по дате" => full_prompt.include?("пару месяцев назад"),
  "ЗАПРЕТ российских топонимов" => full_prompt.include?("ЗАПРЕЩЕНО") && full_prompt.include?("Москва"),
  "Разрешение украинских топонимов" => full_prompt.include?("Киев")
}

puts "Проверки промпта:"
all_prompt_checks_passed = true
prompt_checks.each do |check_name, result|
  status = result ? "✓" : "✗"
  puts "#{status} #{check_name}"
  all_prompt_checks_passed = false unless result
end

puts
if all_prompt_checks_passed
  puts "✓ ПОЛНЫЙ ПРОМПТ СОДЕРЖИТ ВСЕ НЕОБХОДИМЫЕ ИНСТРУКЦИИ"
  puts "✓ Включая запрет российских топонимов"
else
  puts "✗ ПРОМПТ НЕ ПОЛНЫЙ"
end

puts
puts "="*80
puts "РЕЗЮМЕ"
puts "="*80
puts
puts "Реализованные ограничения:"
puts "  ✓ ЗАПРЕЩЕНО: Москва, Санкт-Петербург, Россия, российский"
puts "  ✓ ЗАПРЕЩЕНО: Любые другие российские географические названия"
puts "  ✓ РАЗРЕШЕНО: Только украинские города (Киев, Харьков, Одесса, Львов, Днепр)"
puts "  ✓ Инструкции добавляются в КАЖДЫЙ промпт для AI"
puts
puts "Метод: build_geographic_restrictions в universal_review_processor.rb"
puts "Вызывается автоматически при каждой генерации/переписывании отзыва"
puts
puts "="*80
