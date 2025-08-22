# lib/tasks/ai_reviews.rake

namespace :ai_reviews do
  desc "Показать текущие настройки AI системы"
  task status: :environment do
    puts "\n=== Статус AI системы генерации отзывов ==="
    puts
    
    settings = FeatureFlags.current_settings
    settings.each do |key, value|
      status = value.is_a?(TrueClass) ? "✅" : (value.is_a?(FalseClass) ? "❌" : value)
      puts "#{key.to_s.humanize}: #{status}"
    end
    
    puts "\n=== Статистика затрат ==="
    cost_tracker = AiCostTracker.new
    daily_stats = cost_tracker.daily_stats
    
    puts "Потрачено сегодня: $#{daily_stats[:total_cost].round(2)}"
    puts "Остаток бюджета: $#{daily_stats[:remaining_budget].round(2)}"
    puts "Запросов сегодня: #{daily_stats[:requests_count]}"
    puts "Средняя стоимость запроса: $#{daily_stats[:average_cost_per_request].round(4)}" if daily_stats[:average_cost_per_request] > 0
    puts "Лимит превышен: #{daily_stats[:limit_exceeded] ? '⚠️  ДА' : '✅ НЕТ'}"
    
    puts "\n=== Использование моделей ==="
    model_stats = cost_tracker.model_usage_stats
    model_stats.each do |model, stats|
      next if stats[:requests] == 0
      puts "#{model}: #{stats[:requests]} запросов, $#{stats[:cost].round(2)}"
    end
  end
  
  desc "Включить AI обработку для процента пользователей (например: ai_reviews:enable[25])"
  task :enable, [:percentage] => :environment do |t, args|
    percentage = args[:percentage]&.to_i || 10
    
    FeatureFlags.set_ai_processing_percentage(percentage)
    puts "✅ AI обработка включена для #{percentage}% пользователей"
  end
  
  desc "Отключить AI обработку"
  task disable: :environment do
    FeatureFlags.set_ai_processing_percentage(0)
    puts "❌ AI обработка отключена"
  end
  
  desc "Включить умные эмодзи"
  task enable_smart_emoji: :environment do
    FeatureFlags.enable_smart_emoji!
    puts "✅ Умные эмодзи включены"
  end
  
  desc "Отключить умные эмодзи"
  task disable_smart_emoji: :environment do
    FeatureFlags.disable_smart_emoji!
    puts "❌ Умные эмодзи отключены"
  end
  
  desc "Включить контроль длины"
  task enable_length_control: :environment do
    FeatureFlags.enable_length_control!
    puts "✅ Контроль длины включен"
  end
  
  desc "Отключить контроль длины"
  task disable_length_control: :environment do
    FeatureFlags.disable_length_control!
    puts "❌ Контроль длины отключен"
  end
  
  desc "Постепенно увеличить процент AI обработки"
  task gradually_increase: :environment do
    new_percentage = FeatureFlags.gradually_increase_ai_percentage!
    puts "📈 Процент AI обработки увеличен до #{new_percentage}%"
  end
  
  desc "Экстренно отключить AI при проблемах"
  task emergency_disable: :environment do
    FeatureFlags.emergency_disable_ai!
    puts "🚨 AI обработка экстренно отключена!"
  end
  
  desc "Сбросить все настройки к значениям по умолчанию"
  task reset: :environment do
    FeatureFlags.reset_to_defaults!
    puts "🔄 Все настройки сброшены к значениям по умолчанию"
  end
  
  desc "Тестировать новый алгоритм (генерация 5 отзывов)"
  task test: :environment do
    puts "\n=== Тестирование нового алгоритма ==="
    puts
    
    # Временно включаем AI обработку для теста
    original_setting = FeatureFlags.force_ai_processing?
    FeatureFlags.enable_force_ai_processing!
    
    begin
      # Тестовые данные
      test_tyres = [
        {
          brand: "michelin",
          model: "pilot_sport_4",
          season: 1,  # летние
          width: 225,
          height: 45,
          diameter: 17,
          type_review: 1,  # положительный
          id: "test1"
        },
        {
          brand: "continental",
          model: "winter_contact",
          season: 2,  # зимние
          width: 205,
          height: 55,
          diameter: 16,
          type_review: -1,  # негативный
          id: "test2"
        }
      ]
      
      puts "Генерируем тестовые отзывы..."
      
      # Используем сервис напрямую
      service = Object.new
      service.extend(ServiceReviewOut)
      
      results = service.collect_the_answer_v2(test_tyres)
      
      results.each_with_index do |result, index|
        puts "\n--- Отзыв #{index + 1} ---"
        puts "Бренд: #{result[:brand]}"
        puts "Модель: #{result[:model]}"
        puts "Размер: #{result[:tyres_size]}"
        puts "Тип: #{result[:type_review] == 1 ? 'Положительный' : (result[:type_review] == -1 ? 'Негативный' : 'Нейтральный')}"
        puts "Автор: #{result[:author]}"
        puts "Язык: #{result[:language]}"
        puts "Отзыв: #{result[:review]}"
        puts
      end
      
    rescue => e
      puts "❌ Ошибка при тестировании: #{e.message}"
      puts e.backtrace.first(3)
    ensure
      # Возвращаем исходную настройку
      if original_setting
        FeatureFlags.enable_force_ai_processing!
      else
        FeatureFlags.disable_force_ai_processing!
      end
    end
  end
  
  desc "Показать недельную статистику затрат"
  task weekly_stats: :environment do
    puts "\n=== Недельная статистика затрат ==="
    puts
    
    cost_tracker = AiCostTracker.new
    weekly_stats = cost_tracker.weekly_stats
    
    puts "Затраты по дням:"
    weekly_stats[:daily_costs].each do |day_stat|
      date = Date.parse(day_stat[:date]).strftime('%d.%m.%Y')
      cost = day_stat[:cost].round(2)
      puts "  #{date}: $#{cost}"
    end
    
    puts
    puts "Общие затраты за неделю: $#{weekly_stats[:total_week_cost].round(2)}"
    puts "Средние затраты в день: $#{weekly_stats[:average_daily_cost].round(2)}"
  end
  
  desc "Настроить модели AI (показать доступные модели)"
  task show_models: :environment do
    puts "\n=== Доступные модели AI ==="
    puts
    
    ContentWriter::MODELS.each do |purpose, model|
      puts "#{purpose.to_s.humanize}: #{model}"
    end
    
    puts "\n=== Стоимость моделей (за 1M токенов) ==="
    puts
    
    AiCostTracker::MODEL_PRICING.each do |model, pricing|
      puts "#{model}:"
      puts "  Входные токены: $#{pricing[:input]}"
      puts "  Выходные токены: $#{pricing[:output]}"
      puts
    end
  end
  
  desc 'Включить/выключить универсальную постобработку для уникальности всех отзывов'
  task :toggle_universal_processing, [:enabled] => :environment do |t, args|
    enabled = args[:enabled]&.downcase == 'true'
    
    FeatureFlags.set_setting(:universal_postprocessing_enabled, enabled)
    
    status = enabled ? "✅ включена" : "❌ отключена"
    puts "🔄 Универсальная постобработка #{status}"
    puts ""
    puts "📋 Текущие настройки:"
    puts "   Универсальная постобработка: #{FeatureFlags.universal_postprocessing_enabled? ? 'включена' : 'отключена'}"
    puts "   AI обработка: #{FeatureFlags.get_setting(:ai_processing_percentage)}%"
    puts "   Умные эмодзи: #{FeatureFlags.smart_emoji_enabled? ? 'включены' : 'отключены'}"
  end
end

