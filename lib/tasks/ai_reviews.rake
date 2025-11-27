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
  
  # ============ DeepSeek задачи ============
  
  desc "Включить DeepSeek для SEO-текстов (экономия 90%)"
  task enable_deepseek_seo: :environment do
    if ENV['DEEPSEEK_API_KEY'].blank?
      puts "❌ ОШИБКА: DeepSeek API ключ не настроен!"
      puts "   Добавьте DEEPSEEK_API_KEY в .env файл"
      exit 1
    end
    
    FeatureFlags.enable_deepseek_for_seo!
    puts "✅ DeepSeek включен для SEO-текстов (экономия ~90%)"
    puts "   Все SEO-тексты теперь используют DeepSeek-V3"
  end
  
  desc "Отключить DeepSeek для SEO-текстов"
  task disable_deepseek_seo: :environment do
    FeatureFlags.disable_deepseek_for_seo!
    puts "❌ DeepSeek отключен для SEO-текстов"
    puts "   Используется стандартная модель GPT-4o"
  end
  
  desc "Включить DeepSeek для отзывов в льготные часы (16:30-00:30 UTC)"
  task enable_deepseek_reviews: :environment do
    if ENV['DEEPSEEK_API_KEY'].blank?
      puts "❌ ОШИБКА: DeepSeek API ключ не настроен!"
      puts "   Добавьте DEEPSEEK_API_KEY в .env файл"
      exit 1
    end
    
    FeatureFlags.enable_deepseek_for_reviews!
    puts "✅ DeepSeek включен для отзывов в льготные часы"
    puts "   Льготные часы UTC: 16:30-00:30 (в 2 раза дешевле)"
    puts "   Для Киева (UTC+2): 18:30-02:30"
  end
  
  desc "Отключить DeepSeek для отзывов"
  task disable_deepseek_reviews: :environment do
    FeatureFlags.disable_deepseek_for_reviews!
    puts "❌ DeepSeek отключен для отзывов"
  end
  
  desc "Проверить статус DeepSeek"
  task deepseek_status: :environment do
    puts "\n=== Статус DeepSeek интеграции ==="
    puts
    
    # Проверяем наличие API ключа
    if ENV['DEEPSEEK_API_KEY'].present?
      puts "✅ API ключ DeepSeek настроен"
    else
      puts "❌ API ключ DeepSeek НЕ настроен"
      puts "   Добавьте DEEPSEEK_API_KEY=your_key в .env файл"
    end
    
    # Проверяем текущее время
    is_discount = AiCostTracker.deepseek_discount_time?
    current_time = Time.now.utc
    puts "\n⏰ Текущее время UTC: #{current_time.strftime('%H:%M')}"
    puts "   Льготный тариф: #{is_discount ? '✅ ДА (в 2 раза дешевле!)' : '❌ НЕТ'}"
    puts "   Льготные часы UTC: 16:30-00:30"
    
    # Показываем настройки
    puts "\n📋 Настройки DeepSeek:"
    puts "   SEO-тексты: #{FeatureFlags.use_deepseek_for_seo? ? '✅ включено' : '❌ отключено'}"
    puts "   Отзывы (льготные часы): #{FeatureFlags.use_deepseek_for_reviews? ? '✅ включено' : '❌ отключено'}"
    
    # Показываем цены
    puts "\n💰 Цены DeepSeek за 1M токенов:"
    puts "   Стандартные часы:"
    puts "     Input: $0.27 | Output: $1.10"
    puts "   Льготные часы (16:30-00:30 UTC):"
    puts "     Input: $0.135 | Output: $0.55"
    puts
    puts "   Для сравнения GPT-4o:"
    puts "     Input: $2.50 | Output: $10.00"
    puts
    puts "   💎 Экономия: DeepSeek в 9-18× дешевле GPT-4o!"
  end
  
  desc "Тестировать DeepSeek (генерация SEO-текста)"
  task test_deepseek: :environment do
    if ENV['DEEPSEEK_API_KEY'].blank?
      puts "❌ ОШИБКА: DeepSeek API ключ не настроен!"
      puts "   Добавьте DEEPSEEK_API_KEY в .env файл"
      exit 1
    end
    
    puts "\n=== Тестирование DeepSeek API ==="
    puts
    
    # Временно включаем DeepSeek
    original_seo_setting = FeatureFlags.use_deepseek_for_seo?
    FeatureFlags.enable_deepseek_for_seo!
    
    begin
      puts "Генерируем тестовый SEO-текст через DeepSeek..."
      puts
      
      content_writer = ContentWriter.new
      
      test_prompt = <<~PROMPT
        Создай короткий SEO-текст (200-300 слов) для интернет-магазина шин ProKoleso.
        
        Параметры:
        - Бренд: Michelin
        - Модель: Pilot Sport 4
        - Сезон: летние
        - Размер: 225/45 R17
        
        Текст должен быть информативным и содержать 2-3 абзаца с описанием преимуществ.
      PROMPT
      
      start_time = Time.now
      response = content_writer.write_seo_text(test_prompt, 500)
      end_time = Time.now
      
      if response && response['choices'] && response['choices'][0]
        text = response['choices'][0]['message']['content']
        
        puts "✅ Успешно! Текст сгенерирован за #{(end_time - start_time).round(2)} сек"
        puts
        puts "--- Сгенерированный текст ---"
        puts text
        puts "--- Конец текста ---"
        puts
        
        # Показываем использование токенов
        if response['usage']
          input_tokens = response['usage']['prompt_tokens'] || 0
          output_tokens = response['usage']['completion_tokens'] || 0
          total_tokens = response['usage']['total_tokens'] || 0
          
          puts "📊 Использование токенов:"
          puts "   Входные: #{input_tokens}"
          puts "   Выходные: #{output_tokens}"
          puts "   Всего: #{total_tokens}"
          
          # Рассчитываем стоимость
          cost_tracker = AiCostTracker.new
          model = 'deepseek-chat'
          effective_model = AiCostTracker.effective_model_name(model)
          pricing = AiCostTracker::MODEL_PRICING[effective_model]
          
          if pricing
            cost = (input_tokens / 1_000_000.0) * pricing[:input] + 
                   (output_tokens / 1_000_000.0) * pricing[:output]
            puts "   💰 Стоимость: $#{cost.round(6)}"
            puts
            puts "   🎯 Льготный тариф: #{effective_model.include?('discount') ? 'ДА' : 'НЕТ'}"
          end
        end
        
        puts "\n✅ Тест DeepSeek успешно пройден!"
      else
        puts "❌ Ошибка: пустой ответ от API"
      end
      
    rescue => e
      puts "❌ Ошибка при тестировании: #{e.message}"
      puts e.backtrace.first(5)
    ensure
      # Возвращаем исходную настройку
      if original_seo_setting
        FeatureFlags.enable_deepseek_for_seo!
      else
        FeatureFlags.disable_deepseek_for_seo!
      end
    end
  end
  
  desc "Показать экономию от использования DeepSeek"
  task calculate_savings: :environment do
    puts "\n=== Калькулятор экономии DeepSeek ==="
    puts
    
    # Примерные объемы
    seo_texts_per_day = 100
    reviews_per_day = 1000
    
    # Средние токены
    seo_input_tokens = 2000
    seo_output_tokens = 3000
    review_input_tokens = 500
    review_output_tokens = 400
    
    # Цены GPT-4o
    gpt4o_input = 2.50
    gpt4o_output = 10.0
    gpt4o_mini_input = 0.15
    gpt4o_mini_output = 0.6
    
    # Цены DeepSeek (стандартные)
    deepseek_input = 0.27
    deepseek_output = 1.10
    
    # Цены DeepSeek (льготные)
    deepseek_discount_input = 0.135
    deepseek_discount_output = 0.55
    
    # Расчет для SEO-текстов
    seo_gpt_cost = seo_texts_per_day * (
      (seo_input_tokens / 1_000_000.0) * gpt4o_input +
      (seo_output_tokens / 1_000_000.0) * gpt4o_output
    )
    
    seo_deepseek_cost = seo_texts_per_day * (
      (seo_input_tokens / 1_000_000.0) * deepseek_input +
      (seo_output_tokens / 1_000_000.0) * deepseek_output
    )
    
    seo_savings = seo_gpt_cost - seo_deepseek_cost
    
    # Расчет для отзывов (льготные часы)
    reviews_gpt_cost = reviews_per_day * (
      (review_input_tokens / 1_000_000.0) * gpt4o_mini_input +
      (review_output_tokens / 1_000_000.0) * gpt4o_mini_output
    )
    
    reviews_deepseek_cost = reviews_per_day * (
      (review_input_tokens / 1_000_000.0) * deepseek_discount_input +
      (review_output_tokens / 1_000_000.0) * deepseek_discount_output
    )
    
    reviews_savings = reviews_gpt_cost - reviews_deepseek_cost
    
    puts "📊 При объеме:"
    puts "   SEO-тексты: #{seo_texts_per_day} в день"
    puts "   Отзывы: #{reviews_per_day} в день"
    puts
    
    puts "💰 SEO-тексты (GPT-4o → DeepSeek):"
    puts "   Было: $#{seo_gpt_cost.round(2)}/день"
    puts "   Стало: $#{seo_deepseek_cost.round(2)}/день"
    puts "   ✅ Экономия: $#{seo_savings.round(2)}/день ($#{(seo_savings * 30).round(2)}/месяц)"
    puts
    
    puts "💰 Отзывы (gpt-4o-mini → DeepSeek льготные часы):"
    puts "   Было: $#{reviews_gpt_cost.round(2)}/день"
    puts "   Стало: $#{reviews_deepseek_cost.round(2)}/день"
    puts "   ✅ Экономия: $#{reviews_savings.round(2)}/день ($#{(reviews_savings * 30).round(2)}/месяц)"
    puts
    
    total_savings = seo_savings + reviews_savings
    puts "🎉 ИТОГО ЭКОНОМИЯ:"
    puts "   День: $#{total_savings.round(2)}"
    puts "   Месяц: $#{(total_savings * 30).round(2)}"
    puts "   Год: $#{(total_savings * 365).round(2)}"
    puts
    puts "   💎 Снижение затрат на #{((total_savings / (seo_gpt_cost + reviews_gpt_cost)) * 100).round(1)}%!"
  end

  # ============ Rate Limiting задачи ============

  desc "Показать статистику rate limiting"
  task rate_limit_stats: :environment do
    puts "\n=== Rate Limiting Statistics ==="
    puts

    rate_limiter = AiRateLimiter.new
    stats = rate_limiter.stats

    puts "Модель                  | RPM (тек/лим) | Concurrent (тек/лим) | Доступно"
    puts "-" * 75

    stats.each do |stat|
      rpm_status = "#{stat[:current_rpm]}/#{stat[:rpm_limit]}"
      concurrent_status = "#{stat[:current_concurrent]}/#{stat[:concurrent_limit]}"
      available = stat[:available_capacity]

      puts "%-22s | %-13s | %-20s | %d" % [
        stat[:model],
        rpm_status,
        concurrent_status,
        available
      ]
    end

    puts
    puts "RPM = Requests Per Minute"
    puts "Concurrent = Параллельные запросы в данный момент"
    puts "Доступно = Сколько ещё запросов можно отправить"
  end

  desc "Показать полный статус системы (включая rate limits)"
  task full_status: :environment do
    Rake::Task["ai_reviews:status"].invoke
    puts
    Rake::Task["ai_reviews:rate_limit_stats"].invoke
  end
end

