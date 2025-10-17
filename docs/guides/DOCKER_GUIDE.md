# Руководство по Docker для Create Keywords API

## Файлы Docker

### 1. `Dockerfile` - Основной файл для продакшена
- Использует Ruby 3.3.8
- Настроен для работы с OpenAI API и DeepSeek API
- Включает установку всех зависимостей
- Поддержка двух AI провайдеров

### 2. `Dockerfile_old` - Альтернативный многоэтапный Dockerfile
- Оптимизированный для продакшена
- Использует multi-stage build для уменьшения размера образа
- Обновлен до Ruby 3.3.8

### 3. `docker-compose.yml` - Для разработки
- Настроен для локальной разработки
- Включает volume mounting для hot reload
- Настроен сервис worker для выполнения rake задач

## Команды для запуска

### Простая сборка и запуск (используя Dockerfile)

#### Вариант 1: Только OpenAI (без DeepSeek)
```bash
# Сборка образа с передачей API ключа
sudo docker build --build-arg OPENAI_API_KEY=your_openai_api_key -t create-keywords-api .

# Запуск контейнера
sudo docker run --rm -p 3000:3000 create-keywords-api
```

**⚠️ Внимание:** Без DeepSeek затраты будут на 90% выше!

#### Вариант 2: С DeepSeek (рекомендуется, экономия 90%)
```bash
# Сборка образа с обоими API ключами
sudo docker build \
  --build-arg OPENAI_API_KEY=your_openai_api_key \
  --build-arg DEEPSEEK_API_KEY=your_deepseek_api_key \
  -t create-keywords-api .

# Запуск контейнера
sudo docker run --rm -p 3000:3000 create-keywords-api
```

**✅ Рекомендуется:** DeepSeek используется по умолчанию, OpenAI - только как fallback

### Использование docker-compose (рекомендуется для разработки)

#### Шаг 1: Настройка .env файла
```bash
# Создайте .env файл с обоими API ключами
cat > .env << 'EOF'
OPENAI_API_KEY=your_openai_api_key_here
DEEPSEEK_API_KEY=your_deepseek_api_key_here
EOF
```

**💡 Совет:** Скопируйте `.env.example` и заполните своими ключами:
```bash
cp .env.example .env
# Отредактируйте .env файл
```

#### Шаг 2: Запуск сервисов
```bash
# Запуск всех сервисов
docker-compose up

# Запуск в фоновом режиме
docker-compose up -d

# Остановка всех сервисов
docker-compose down

# Пересборка образов (после изменения Dockerfile)
docker-compose build

# Полная пересборка без кэша
docker-compose build --no-cache
```

### Выполнение команд в контейнере
```bash
# Выполнение rails команд
docker-compose exec web rails console
docker-compose exec web rails ai_reviews:status

# Проверка DeepSeek интеграции
docker-compose exec web rails ai_reviews:deepseek_status
docker-compose exec web rails ai_reviews:test_deepseek

# Выполнение в worker контейнере
docker-compose exec worker rails ai_reviews:generate

# Bash в контейнере
docker-compose exec web bash
```

### Работа с базой данных
```bash
# Создание базы данных
docker-compose exec web rails db:create

# Миграции
docker-compose exec web rails db:migrate

# Seed данные
docker-compose exec web rails db:seed
```

## Переменные окружения

Убедитесь, что в файле `.env` указаны необходимые переменные:

### Обязательные:
```bash
OPENAI_API_KEY=your_openai_api_key_here
```

### Рекомендуемые (для экономии 90%):
```bash
DEEPSEEK_API_KEY=your_deepseek_api_key_here
```

### Полный пример .env файла:
```bash
# OpenAI API (обязательно)
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxx

# DeepSeek API (рекомендуется для экономии 90%)
DEEPSEEK_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxx

# Rails Configuration
RAILS_ENV=development
SECRET_KEY_BASE=your_secret_key_base

# Database (если используется PostgreSQL)
# DATABASE_URL=postgresql://user:password@localhost/database_name
```

**💡 Важно:**
- Без `DEEPSEEK_API_KEY` приложение будет работать, но использовать OpenAI (дороже в 10 раз)
- С `DEEPSEEK_API_KEY` автоматическая экономия до 90% на всех операциях

## Полезные команды

### Очистка Docker ресурсов
```bash
# Удаление неиспользуемых образов
docker system prune

# Удаление всех контейнеров и образов
docker system prune -a

# Удаление volumes
docker volume prune
```

### Логи
```bash
# Просмотр логов всех сервисов
docker-compose logs

# Просмотр логов конкретного сервиса
docker-compose logs web

# Следование за логами в реальном времени
docker-compose logs -f web
```

## 🔍 Проверка DeepSeek в Docker

После запуска контейнера проверьте интеграцию DeepSeek:

```bash
# Проверить статус DeepSeek
docker-compose exec web rails ai_reviews:deepseek_status

# Протестировать DeepSeek API
docker-compose exec web rails ai_reviews:test_deepseek

# Показать экономию
docker-compose exec web rails ai_reviews:calculate_savings
```

### Ожидаемый вывод:
```
=== Статус DeepSeek интеграции ===

✅ API ключ DeepSeek настроен

⏰ Текущее время UTC: 04:18
   Льготный тариф: ✅ ДА (в 2 раза дешевле!)
   Льготные часы UTC: 16:30-00:30

📋 Настройки DeepSeek:
   SEO-тексты: ✅ включено
   Отзывы (льготные часы): ✅ включено

💎 Экономия: DeepSeek в 9-18× дешевле GPT-4o!
```

---

## Troubleshooting

### Проблема: DeepSeek API ключ не распознается

**Решение:**
```bash
# Проверьте .env файл
cat .env | grep DEEPSEEK

# Пересоберите образ с новыми переменными
docker-compose down
docker-compose build --no-cache
docker-compose up
```

### Проблема: "DeepSeek client not available"

**Причина:** API ключ не передан в контейнер

**Решение:**
```bash
# Убедитесь, что DEEPSEEK_API_KEY в .env
echo "DEEPSEEK_API_KEY=your_key" >> .env

# Перезапустите
docker-compose restart web
```

### Проблемы с правами доступа
Если возникают проблемы с правами доступа к файлам, используйте:
```bash
sudo chown -R $USER:$USER .
```

### Проблемы с bundle
Если возникают проблемы с gem'ами, пересоберите образ:
```bash
docker-compose build --no-cache web
```

### Проблемы с базой данных
Если база данных повреждена, удалите volume и пересоздайте:
```bash
docker-compose down -v
docker-compose up
```
