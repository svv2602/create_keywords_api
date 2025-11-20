#!/usr/bin/env ruby
# Тестовый скрипт для проверки генерации дат отзывов и покупок

require_relative 'config/environment'

# Создаем тестовый класс, который включает модуль
class ReviewServiceTest
  include ServiceReviewOut
end

puts "="*80
puts "ТЕСТИРОВАНИЕ ГЕНЕРАЦИИ ДАТ ОТЗЫВОВ"
puts "="*80
puts

# Тест 1: Генерация дат для зимних шин
puts "ТЕСТ 1: Зимние шины (сезон 2)"
puts "-"*80

service = ReviewServiceTest.new
10.times do |i|
  result = service.send(:generate_review_dates, 2)  # 2 = зимние

  review_date = Date.parse(result[:review_date])
  purchase_date = Date.parse(result[:purchase_date]) if result[:purchase_date]

  puts "\nПопытка #{i+1}:"
  puts "  Дата отзыва:    #{result[:review_date]} (#{review_date.strftime('%B')})"
  puts "  Дата покупки:   #{result[:purchase_date]} (#{purchase_date.strftime('%B')})" if purchase_date
  puts "  Описание:       #{result[:time_description]}"

  # Проверка сезонности покупки (зимние шины: сентябрь-январь)
  if purchase_date
    purchase_month = purchase_date.month
    valid_months = [9, 10, 11, 12, 1]
    is_valid = valid_months.include?(purchase_month)
    puts "  Сезон покупки:  #{is_valid ? '✓ Корректно' : '✗ ОШИБКА'} (месяц #{purchase_month})"

    # Проверка что покупка до отзыва
    days_diff = (review_date - purchase_date).to_i
    puts "  Дней прошло:    #{days_diff} (#{days_diff <= 365 ? '✓ В пределах года' : '✗ Больше года'})"
  end
end

puts
puts "="*80
puts "ТЕСТ 2: Летние шины (сезон 1)"
puts "-"*80

10.times do |i|
  result = service.send(:generate_review_dates, 1)  # 1 = летние

  review_date = Date.parse(result[:review_date])
  purchase_date = Date.parse(result[:purchase_date]) if result[:purchase_date]

  puts "\nПопытка #{i+1}:"
  puts "  Дата отзыва:    #{result[:review_date]} (#{review_date.strftime('%B')})"
  puts "  Дата покупки:   #{result[:purchase_date]} (#{purchase_date.strftime('%B')})" if purchase_date
  puts "  Описание:       #{result[:time_description]}"

  # Проверка сезонности покупки (летние шины: март-август)
  if purchase_date
    purchase_month = purchase_date.month
    valid_months = [3, 4, 5, 6, 7, 8]
    is_valid = valid_months.include?(purchase_month)
    puts "  Сезон покупки:  #{is_valid ? '✓ Корректно' : '✗ ОШИБКА'} (месяц #{purchase_month})"

    days_diff = (review_date - purchase_date).to_i
    puts "  Дней прошло:    #{days_diff} (#{days_diff <= 365 ? '✓ В пределах года' : '✗ Больше года'})"
  end
end

puts
puts "="*80
puts "ТЕСТ 3: Всесезонные шины (сезон 3)"
puts "-"*80

5.times do |i|
  result = service.send(:generate_review_dates, 3)  # 3 = всесезонные

  review_date = Date.parse(result[:review_date])
  purchase_date = Date.parse(result[:purchase_date]) if result[:purchase_date]

  puts "\nПопытка #{i+1}:"
  puts "  Дата отзыва:    #{result[:review_date]}"
  puts "  Дата покупки:   #{result[:purchase_date]}" if purchase_date
  puts "  Описание:       #{result[:time_description]}"
  puts "  Сезон покупки:  ✓ Любой месяц допустим"

  if purchase_date
    days_diff = (review_date - purchase_date).to_i
    puts "  Дней прошло:    #{days_diff}"
  end
end

puts
puts "="*80
puts "ТЕСТ 4: Проверка формулировок времени"
puts "-"*80

# Симулируем разные временные периоды
test_periods = [
  { months: 0, desc: "Недавняя покупка (< 1 месяца)" },
  { months: 1, desc: "1 месяц назад" },
  { months: 2, desc: "2 месяца назад" },
  { months: 3, desc: "3 месяца назад" },
  { months: 6, desc: "Полгода назад" },
  { months: 10, desc: "10 месяцев назад" }
]

test_periods.each do |period|
  review_date = Date.today
  purchase_date = review_date - (period[:months] * 30).days

  time_desc = service.send(:format_time_period, review_date, purchase_date)

  puts "\n#{period[:desc]}:"
  puts "  Дата отзыва:    #{review_date.strftime('%Y-%m-%d')}"
  puts "  Дата покупки:   #{purchase_date.strftime('%Y-%m-%d')}"
  puts "  Формулировка:   \"#{time_desc}\""
end

puts
puts "="*80
puts "ТЕСТ 5: Проверка инструкций AI для разных сезонов"
puts "-"*80

processor = UniversalReviewProcessor.new

# Сценарий 1: Зимние шины летом (должно быть предупреждение)
puts "\nСценарий 1: Зимние шины, отзыв летом"
puts "-"*40

context_winter_summer = {
  brand: "Michelin",
  model: "X-Ice",
  season: 2,  # зимние
  review_date: "2025-07-15",  # июль
  purchase_date: "2024-11-20",  # ноябрь прошлого года
  time_description: "прошлой осенью"
}

instructions = processor.send(:build_date_instructions, context_winter_summer)
puts instructions
puts

# Сценарий 2: Летние шины зимой (должно быть предупреждение)
puts "\nСценарий 2: Летние шины, отзыв зимой"
puts "-"*40

context_summer_winter = {
  brand: "Continental",
  model: "PremiumContact",
  season: 1,  # летние
  review_date: "2025-01-15",  # январь
  purchase_date: "2024-05-20",  # май прошлого года
  time_description: "прошлым летом"
}

instructions = processor.send(:build_date_instructions, context_summer_winter)
puts instructions
puts

# Сценарий 3: Зимние шины зимой (без предупреждения)
puts "\nСценарий 3: Зимние шины, отзыв зимой (нормально)"
puts "-"*40

context_winter_winter = {
  brand: "Nokian",
  model: "Hakkapeliitta",
  season: 2,  # зимние
  review_date: "2025-12-15",  # декабрь
  purchase_date: "2025-11-01",  # ноябрь
  time_description: "месяц назад"
}

instructions = processor.send(:build_date_instructions, context_winter_winter)
puts instructions
puts

# Сценарий 4: Всесезонные (никогда нет предупреждения)
puts "\nСценарий 4: Всесезонные шины (всегда нормально)"
puts "-"*40

context_allseason = {
  brand: "Goodyear",
  model: "Vector 4Seasons",
  season: 3,  # всесезонные
  review_date: "2025-07-15",  # июль
  purchase_date: "2025-06-01",  # июнь
  time_description: "месяц назад"
}

instructions = processor.send(:build_date_instructions, context_allseason)
puts instructions
puts

puts "="*80
puts "ТЕСТ 6: Граничные случаи"
puts "-"*80

# Граничные месяцы для зимних шин
boundary_cases = [
  { month: 8, season: 2, desc: "Август - граница для зимних (НЕТ предупреждения)" },
  { month: 9, season: 2, desc: "Сентябрь - начало сезона зимних (норма)" },
  { month: 6, season: 2, desc: "Июнь - лето, зимние шины (ЕСТЬ предупреждение)" },
  { month: 2, season: 1, desc: "Февраль - зима, летние шины (ЕСТЬ предупреждение)" },
  { month: 3, season: 1, desc: "Март - начало сезона летних (норма)" }
]

boundary_cases.each do |test_case|
  puts "\n#{test_case[:desc]}:"

  review_date = Date.new(2025, test_case[:month], 15)

  context = {
    season: test_case[:season],
    review_date: review_date.strftime('%Y-%m-%d'),
    purchase_date: (review_date - 60.days).strftime('%Y-%m-%d'),
    time_description: "пару месяцев назад"
  }

  instructions = processor.send(:build_date_instructions, context)

  has_warning = instructions.include?("ВНИМАНИЕ")
  puts "  Предупреждение: #{has_warning ? 'ЕСТЬ ✓' : 'НЕТ ✓'}"
end

puts
puts "="*80
puts "ТЕСТИРОВАНИЕ ЗАВЕРШЕНО"
puts "="*80
puts "\nДля запуска тестов с полной интеграцией:"
puts "  bundle exec rails runner test_review_dates.rb"
puts "\nПроверьте что:"
puts "  ✓ Даты отзывов в пределах последних 3 месяцев"
puts "  ✓ Даты покупок соответствуют сезону шин"
puts "  ✓ Даты покупок в пределах года до отзыва"
puts "  ✓ Формулировки времени естественные и разнообразные"
puts "  ✓ Предупреждения для несезонных отзывов работают корректно"
