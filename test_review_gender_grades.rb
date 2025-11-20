#!/usr/bin/env ruby
# Тестовый скрипт для проверки новой логики генерации отзывов с учетом пола и оценок

require_relative 'config/environment'

puts "="*80
puts "ТЕСТИРОВАНИЕ НОВОЙ ЛОГИКИ ГЕНЕРАЦИИ ОТЗЫВОВ"
puts "="*80
puts

# Тест 1: Женщина с высокой оценкой
puts "ТЕСТ 1: Женщина с высокой оценкой (4.5)"
puts "-"*80

context_female_high = {
  brand: "Michelin",
  model: "Pilot Sport 4",
  car: "BMW 3 Series",
  gender: "женщина",
  grade: 4.5,
  array_average: [4.5, 5.0, 4.0, 4.5],
  type_review: 1,
  season: 1,
  language: "ru"
}

processor = UniversalReviewProcessor.new
original_review = "Отличные шины! Проехала на них 15000 км, в восторге. На мокрой дороге держат отлично."

instructions = processor.send(:build_context_instructions, context_female_high)
puts "Промпт инструкции:"
puts instructions
puts

# Тест 2: Мужчина с низкой оценкой
puts "\nТЕСТ 2: Мужчина с низкой оценкой (2.0)"
puts "-"*80

context_male_low = {
  brand: "Yokohama",
  model: "BluEarth",
  car: "Honda CR-V",
  gender: "мужчина",
  grade: 2.0,
  array_average: [2.0, 1.5, 2.5, 2.0],
  type_review: -1,
  season: 1,
  language: "ru"
}

instructions = processor.send(:build_context_instructions, context_male_low)
puts "Промпт инструкции:"
puts instructions
puts

# Тест 3: Женщина со средней оценкой и разбросом
puts "\nТЕСТ 3: Женщина со средней оценкой с разбросом (3.5)"
puts "-"*80

context_female_mixed = {
  brand: "Continental",
  model: "WinterContact",
  car: "Toyota Camry",
  gender: "женщина",
  grade: 3.5,
  array_average: [5.0, 3.0, 2.5, 4.0, 3.5, 3.5],  # Большой разброс
  type_review: 0,
  season: 2,
  language: "ru"
}

instructions = processor.send(:build_context_instructions, context_female_mixed)
puts "Промпт инструкции:"
puts instructions
puts

puts "="*80
puts "ПРОВЕРКА build_grade_instructions"
puts "="*80

# Тест разных диапазонов оценок
test_grades = [
  { grade: 5.0, average: [5.0, 5.0, 5.0, 5.0], desc: "Максимальная оценка" },
  { grade: 4.2, average: [4.0, 4.5, 4.0, 4.5], desc: "Высокая положительная" },
  { grade: 3.0, average: [3.0, 3.0, 3.0, 3.0], desc: "Нейтральная" },
  { grade: 2.0, average: [2.0, 2.0, 2.0, 2.0], desc: "Низкая негативная" },
  { grade: 1.0, average: [1.0, 1.0, 1.0, 1.0], desc: "Минимальная оценка" },
  { grade: 4.0, average: [5.0, 5.0, 2.0, 4.0], desc: "Высокая с разбросом" }
]

test_grades.each do |test|
  puts "\n#{test[:desc]}: #{test[:grade]}/5"
  puts "-"*40
  grade_instructions = processor.send(:build_grade_instructions, test[:grade], test[:average])
  puts grade_instructions
end

puts "\n"
puts "="*80
puts "ТЕСТИРОВАНИЕ ЗАВЕРШЕНО"
puts "="*80
puts "\nДля полноценного теста запустите:"
puts "  rails runner test_review_gender_grades.rb"
