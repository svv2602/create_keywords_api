# 📚 Документация проекта create_keywords_api

Полная документация по AI-системе генерации контента с интеграцией DeepSeek.

---

## 📁 Структура документации

### 🚀 Быстрый старт

**В корне проекта:**
- **[START_HERE.md](../START_HERE.md)** - главная точка входа, начните отсюда!

**Детальные гайды:**
- **[quickstart/DEEPSEEK_QUICKSTART.md](quickstart/DEEPSEEK_QUICKSTART.md)** - полный гайд по DeepSeek интеграции

---

### 📖 Руководства (guides/)

1. **[AI_REVIEWS_GUIDE.md](guides/AI_REVIEWS_GUIDE.md)**
   - Руководство по AI-системе генерации отзывов
   - Управление через Feature Flags
   - Мониторинг и статистика

2. **[FORCE_MODEL_USAGE.md](guides/FORCE_MODEL_USAGE.md)**
   - Прямое указание AI модели через параметр
   - Примеры использования для Ruby и API
   - Логика выбора модели с приоритетами

3. **[DOCKER_GUIDE.md](guides/DOCKER_GUIDE.md)**
   - Запуск приложения через Docker
   - Конфигурация контейнеров
   - Troubleshooting

---

### 📊 Технические отчеты (reports/)

1. **[DEEPSEEK_INTEGRATION_REPORT.md](reports/DEEPSEEK_INTEGRATION_REPORT.md)**
   - Полный технический отчет о внедрении DeepSeek API
   - Сравнение моделей и цен
   - Финансовая оценка экономии

2. **[DEEPSEEK_DEFAULT_CHANGES.md](reports/DEEPSEEK_DEFAULT_CHANGES.md)**
   - Детальное описание изменений в логике выбора моделей
   - DeepSeek как модель по умолчанию
   - Параметр force_model

---

## 🎯 С чего начать?

### Новый пользователь:
1. Прочитайте **[START_HERE.md](../START_HERE.md)** в корне проекта
2. Для детального изучения: **[quickstart/DEEPSEEK_QUICKSTART.md](quickstart/DEEPSEEK_QUICKSTART.md)**
3. Основная документация: **[README.md](../README.md)**

### Разработчик:
1. **[guides/FORCE_MODEL_USAGE.md](guides/FORCE_MODEL_USAGE.md)** - как работать с моделями
2. **[reports/DEEPSEEK_INTEGRATION_REPORT.md](reports/DEEPSEEK_INTEGRATION_REPORT.md)** - техническая архитектура
3. **[guides/AI_REVIEWS_GUIDE.md](guides/AI_REVIEWS_GUIDE.md)** - система AI отзывов

### DevOps:
1. **[guides/DOCKER_GUIDE.md](guides/DOCKER_GUIDE.md)** - Docker конфигурация
2. **[reports/DEEPSEEK_INTEGRATION_REPORT.md](reports/DEEPSEEK_INTEGRATION_REPORT.md)** - мониторинг и метрики

---

## 📋 Основные темы

### 💎 DeepSeek интеграция
- **Быстрый старт:** [quickstart/DEEPSEEK_QUICKSTART.md](quickstart/DEEPSEEK_QUICKSTART.md)
- **Технический отчет:** [reports/DEEPSEEK_INTEGRATION_REPORT.md](reports/DEEPSEEK_INTEGRATION_REPORT.md)
- **Изменения в 2.0:** [reports/DEEPSEEK_DEFAULT_CHANGES.md](reports/DEEPSEEK_DEFAULT_CHANGES.md)

### 🤖 AI Отзывы
- **Полное руководство:** [guides/AI_REVIEWS_GUIDE.md](guides/AI_REVIEWS_GUIDE.md)
- **Feature Flags:** см. раздел в AI_REVIEWS_GUIDE.md
- **Rake задачи:** `rails ai_reviews:status`

### 🎯 Выбор моделей
- **Прямое указание:** [guides/FORCE_MODEL_USAGE.md](guides/FORCE_MODEL_USAGE.md)
- **По умолчанию:** DeepSeek для всех задач
- **Fallback:** Автоматический переход на OpenAI

### 🐳 Docker
- **Руководство:** [guides/DOCKER_GUIDE.md](guides/DOCKER_GUIDE.md)
- **Запуск:** `docker-compose up`

---

## 🔧 Полезные команды

### DeepSeek:
```bash
rails ai_reviews:deepseek_status    # проверить статус
rails ai_reviews:test_deepseek      # протестировать
rails ai_reviews:calculate_savings  # показать экономию
```

### AI система:
```bash
rails ai_reviews:status             # общий статус
rails ai_reviews:enable[30]         # включить AI для 30%
rails ai_reviews:weekly_stats       # недельная статистика
```

---

## 📞 Поддержка

### Проблемы с DeepSeek:
1. Проверьте: `rails ai_reviews:deepseek_status`
2. Протестируйте: `rails ai_reviews:test_deepseek`
3. См. логи: `tail -f log/development.log | grep -i deepseek`

### Общие вопросы:
- Основная документация: [README.md](../README.md)
- Быстрый старт: [START_HERE.md](../START_HERE.md)

---

## 📈 История версий

### Версия 2.0 (17.10.2025)
- ✅ DeepSeek по умолчанию для всех задач
- ✅ Параметр force_model для прямого выбора модели
- ✅ Обновленная документация
- 📄 См. [reports/DEEPSEEK_DEFAULT_CHANGES.md](reports/DEEPSEEK_DEFAULT_CHANGES.md)

### Версия 1.0 (17.10.2025)
- ✅ Интеграция DeepSeek API
- ✅ Система Feature Flags
- ✅ 7 rake-задач для управления
- 📄 См. [reports/DEEPSEEK_INTEGRATION_REPORT.md](reports/DEEPSEEK_INTEGRATION_REPORT.md)

---

**Последнее обновление:** 17 октября 2025

