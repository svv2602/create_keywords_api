# 🎯 Прямое указание AI модели через параметр

## 📋 Логика выбора модели

### Приоритет выбора (от высшего к низшему):

1. **Параметр `force_model`** → если указан, используется эта модель
2. **DeepSeek (по умолчанию)** → если `force_model` не указан И DeepSeek доступен
3. **OpenAI Fallback** → если DeepSeek недоступен
4. **Fallback при лимитах** → если превышен дневной лимит затрат

---

## 🚀 Использование

### 1. Без параметра (по умолчанию)

```ruby
# DeepSeek используется автоматически
content_writer = ContentWriter.new
response = content_writer.write_seo_text(prompt, 1000)
```

**Что происходит:**
- ✅ Используется DeepSeek (экономия 90%)
- ✅ Если DeepSeek недоступен → автоматический fallback на OpenAI

---

### 2. С указанием конкретной модели

```ruby
# Принудительное использование конкретной модели
content_writer = ContentWriter.new(force_model: 'gpt-4o')
response = content_writer.write_seo_text(prompt, 1000)
```

**Что происходит:**
- ✅ Всегда используется указанная модель (gpt-4o)
- ✅ Игнорируются настройки по умолчанию
- ✅ Не происходит fallback на DeepSeek

---

## 💡 Примеры использования

### Пример 1: SEO-текст с DeepSeek (по умолчанию)

```ruby
# Автоматически используется DeepSeek
writer = ContentWriter.new

prompt = "Создай SEO-текст для шин Michelin Pilot Sport 4"
response = writer.write_seo_text(prompt, 2000)

# Логи:
# => "Using default DeepSeek model: deepseek-chat"
# => Стоимость: ~$0.004 (экономия 90%)
```

---

### Пример 2: SEO-текст с принудительным использованием GPT-4o

```ruby
# Принудительное использование OpenAI
writer = ContentWriter.new(force_model: 'gpt-4o')

prompt = "Создай SEO-текст для шин Michelin Pilot Sport 4"
response = writer.write_seo_text(prompt, 2000)

# Логи:
# => "Using forced model: gpt-4o"
# => Стоимость: ~$0.035 (стандартная цена)
```

---

### Пример 3: Генерация отзывов с DeepSeek

```ruby
# DeepSeek для массовой генерации отзывов
writer = ContentWriter.new

prompt = "Напиши отзыв о зимних шинах Nokian Hakkapeliitta"
response = writer.generate_review(prompt, 500)

# Логи:
# => "Using default DeepSeek model: deepseek-chat"
# => Льготное время: ДА (дополнительная скидка 50%)
# => Стоимость: ~$0.0003
```

---

### Пример 4: Принудительное использование gpt-4o-mini

```ruby
# Быстрая генерация через gpt-4o-mini
writer = ContentWriter.new(force_model: 'gpt-4o-mini')

prompt = "Напиши короткий отзыв"
response = writer.generate_review(prompt, 300)

# Логи:
# => "Using forced model: gpt-4o-mini"
# => Стоимость: ~$0.0003
```

---

## 🎛️ Доступные модели

### DeepSeek модели:
- `deepseek-chat` - универсальная модель (по умолчанию)
- `deepseek-reasoner` - для сложных рассуждений

### OpenAI модели:
- `gpt-4o` - мощная модель ($2.50/$10 за 1M токенов)
- `gpt-4o-mini` - быстрая модель ($0.15/$0.60 за 1M токенов)
- `gpt-3.5-turbo` - fallback модель ($0.50/$1.50 за 1M токенов)

---

## 📊 Сравнение стоимости

### Для SEO-текста (2000 input + 3000 output токенов):

| Модель | Стоимость | Экономия |
|--------|-----------|----------|
| **deepseek-chat** (по умолчанию) | **$0.0037** | **Базовая** ✅ |
| deepseek-chat (льготные часы) | **$0.0019** | **49%** 🔥 |
| gpt-4o | $0.0350 | -846% ❌ |
| gpt-4o-mini | $0.0021 | +43% |

**Вывод:** DeepSeek по умолчанию - оптимальный выбор! 💎

---

## 🔄 Fallback логика

### Автоматические fallback'и:

```ruby
# 1. DeepSeek недоступен
writer = ContentWriter.new
# => Автоматически используется OpenAI (gpt-4o или gpt-4o-mini)
# => Логи: "DeepSeek client not available, falling back to OpenAI"

# 2. Превышен дневной лимит
writer = ContentWriter.new
# => Автоматически используется fallback модель (gpt-4o-mini)
# => Логи: "Daily cost limit exceeded, using fallback model"

# 3. Принудительная модель игнорирует fallback'и
writer = ContentWriter.new(force_model: 'gpt-4o')
# => Всегда используется gpt-4o, независимо от условий
```

---

## 🔧 Использование в контроллерах

### API endpoint для генерации SEO-текстов:

```ruby
# app/controllers/api/v1/seo_texts_controller.rb

def generate_seo_text
  # Получаем параметры
  params_hash = seo_text_params.to_h
  
  # Опциональный параметр модели
  force_model = params[:force_model] # например: 'gpt-4o', 'deepseek-chat'
  
  # Создаем generator с указанием модели
  generator = SeoTextGenerator.new(
    params_hash.merge(force_model: force_model)
  )
  
  # Генерируем текст
  seo_text = generator.generate
  
  render json: { success: true, seo_text: seo_text }
end

private

def seo_text_params
  params.permit(
    :tire_description, :brand, :model, :season, 
    :language, :size, :product_id, :load_index, 
    :speed_index, :seo_requirements, :max_tokens,
    :force_model,  # новый параметр
    links: [:brand, :model, :brand_size, :brand_sezon, :size]
  )
end
```

---

## 📡 API запросы с указанием модели

### Пример 1: DeepSeek (по умолчанию)

```bash
curl -X POST http://localhost:3000/api/v1/generate_seo_text \
  -H "Content-Type: application/json" \
  -d '{
    "tire_description": "<p>Высококачественные зимние шины</p>",
    "brand": "Michelin",
    "model": "Alpin 6",
    "season": "зимние",
    "language": "ru",
    "size": "225/45 R17",
    "product_id": 123
  }'
```

**Используется:** DeepSeek (экономия 90%)

---

### Пример 2: Принудительно GPT-4o

```bash
curl -X POST http://localhost:3000/api/v1/generate_seo_text \
  -H "Content-Type: application/json" \
  -d '{
    "tire_description": "<p>Высококачественные зимние шины</p>",
    "brand": "Michelin",
    "model": "Alpin 6",
    "season": "зимние",
    "language": "ru",
    "size": "225/45 R17",
    "product_id": 123,
    "force_model": "gpt-4o"
  }'
```

**Используется:** GPT-4o (принудительно)

---

### Пример 3: Принудительно gpt-4o-mini

```bash
curl -X POST http://localhost:3000/api/v1/generate_seo_text \
  -H "Content-Type: application/json" \
  -d '{
    "tire_description": "<p>Высококачественные зимние шины</p>",
    "brand": "Michelin",
    "model": "Alpin 6",
    "season": "зимние",
    "language": "ru",
    "size": "225/45 R17",
    "product_id": 123,
    "force_model": "gpt-4o-mini"
  }'
```

**Используется:** gpt-4o-mini (быстрая генерация)

---

## 🎯 Когда использовать force_model?

### ✅ Используйте `force_model`, если:

1. **Тестирование** - хотите сравнить качество разных моделей
2. **A/B тестирование** - проверяете конверсию с разными моделями
3. **Критичный контент** - нужна гарантированно конкретная модель
4. **Особые требования** - специфические задачи под определенную модель

### ❌ НЕ используйте `force_model`, если:

1. **Обычная генерация** - DeepSeek по умолчанию оптимален
2. **Массовое производство** - автоматические fallback'и защищают от проблем
3. **Экономия бюджета** - DeepSeek в 10-20× дешевле OpenAI

---

## 💰 Рекомендации

### Для максимальной экономии:

```ruby
# ✅ Используйте по умолчанию (без force_model)
writer = ContentWriter.new
# DeepSeek автоматически, экономия 90%
```

### Для критичного контента:

```ruby
# ⚠️ Принудительно используйте GPT-4o
writer = ContentWriter.new(force_model: 'gpt-4o')
# Гарантированное качество OpenAI, но дороже
```

### Для быстрой генерации:

```ruby
# ⚡ Используйте gpt-4o-mini
writer = ContentWriter.new(force_model: 'gpt-4o-mini')
# Быстро и дешево
```

---

## 📝 Логирование

Все операции выбора модели логируются:

```ruby
Rails.logger.info "Using forced model: gpt-4o"
Rails.logger.info "Using default DeepSeek model: deepseek-chat"
Rails.logger.warn "DeepSeek client not available, falling back to OpenAI"
Rails.logger.warn "Daily cost limit exceeded, using fallback model"
```

Смотрите логи:
```bash
tail -f log/development.log | grep -i "model"
```

---

## 🎉 Итог

### Логика работы:

1. **Без параметра** → DeepSeek (экономия 90%)
2. **С параметром** → указанная модель (полный контроль)
3. **DeepSeek недоступен** → OpenAI fallback (надежность)
4. **Лимиты превышены** → fallback модель (безопасность)

**Вывод:** В 99% случаев используйте без параметра. DeepSeek по умолчанию - это оптимально! 💎

