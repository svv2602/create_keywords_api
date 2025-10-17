# Руководство по Docker для Create Keywords API

## Файлы Docker

### 1. `Dockerfile` - Основной файл для продакшена
- Использует Ruby 3.3.8
- Настроен для работы с OpenAI API
- Включает установку всех зависимостей

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
```bash
# Сборка образа с передачей API ключа
sudo docker build --build-arg OPENAI_API_KEY=your_openai_api_key -t create-keywords-api .

# Запуск контейнера
sudo docker run --rm -p 3000:3000 create-keywords-api
```

### Использование docker-compose (рекомендуется для разработки)
```bash
# Убедитесь, что в .env файле указан OPENAI_API_KEY
echo "OPENAI_API_KEY=your_openai_api_key" > .env

# Запуск всех сервисов
docker-compose up

# Запуск в фоновом режиме
docker-compose up -d

# Остановка всех сервисов
docker-compose down

# Пересборка образов
docker-compose build
```

### Выполнение команд в контейнере
```bash
# Выполнение rails команд
docker-compose exec web rails console
docker-compose exec web rails ai_reviews:status

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
```
OPENAI_API_KEY=your_openai_api_key_here
```

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

## Troubleshooting

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
