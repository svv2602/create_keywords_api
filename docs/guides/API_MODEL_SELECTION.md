# 🎯 Выбор AI модели через API

## 📋 Обзор

API поддерживает опциональный параметр `force_model` для прямого указания AI модели при генерации контента.

---

## 🚀 Endpoint

**POST** `/api/v1/generate_seo_text`

---

## 📝 Параметры

### Обязательные параметры:

| Параметр | Тип | Описание |
|----------|-----|----------|
| `tire_description` | string | Описание модели шин с HTML-разметкой |
| `brand` | string | Бренд производителя |
| `model` | string | Модель шины |
| `season` | string | Сезон шин (летние/зимние/всесезонные) |
| `language` | string | Язык текста (ru/ua) |
| `size` | string | Размер шин |
| `product_id` | integer | ID товара |

### Опциональные параметры:

| Параметр | Тип | Описание | По умолчанию |
|----------|-----|----------|--------------|
| `force_model` | string | AI модель для генерации | `deepseek-chat` |
| `load_index` | string | Индекс нагрузки | - |
| `speed_index` | string | Индекс скорости | - |
| `seo_requirements` | string | SEO требования | - |
| `max_tokens` | integer | Максимальное количество токенов | 2000 |
| `links` | array | Массив ссылок для вставки в текст | [] |

---

## 💡 Примеры использования

### 1. Без указания модели (DeepSeek по умолчанию)

```bash
curl -X POST http://localhost:3000/api/v1/generate_seo_text \
  -H "Content-Type: application/json" \
  -d '{
    "tire_description": "<p>Высококачественные зимние шины Bridgestone Blizzak-6</p>",
    "brand": "Bridgestone",
    "model": "Blizzak-6",
    "season": "зимние",
    "language": "ru",
    "size": "225/45 R17",
    "product_id": 952,
    "load_index": "99",
    "speed_index": "H"
  }'
```

**Используется:** `deepseek-chat` (по умолчанию)  
**Экономия:** 90% по сравнению с GPT-4o

---

### 2. С принудительным использованием GPT-4o

```bash
curl -X POST http://localhost:3000/api/v1/generate_seo_text \
  -H "Content-Type: application/json" \
  -d '{
    "tire_description": "<p>Высококачественные зимние шины Bridgestone Blizzak-6</p>",
    "brand": "Bridgestone",
    "model": "Blizzak-6",
    "season": "зимние",
    "language": "ru",
    "size": "225/45 R17",
    "product_id": 952,
    "load_index": "99",
    "speed_index": "H",
    "force_model": "gpt-4o"
  }'
```

**Используется:** `gpt-4o` (принудительно)  
**Стоимость:** стандартная цена OpenAI

---

### 3. С использованием gpt-4o-mini

```bash
curl -X POST http://localhost:3000/api/v1/generate_seo_text \
  -H "Content-Type: application/json" \
  -d '{
    "tire_description": "<p>Высококачественные зимние шины Bridgestone Blizzak-6</p>",
    "brand": "Bridgestone",
    "model": "Blizzak-6",
    "season": "зимние",
    "language": "ru",
    "size": "225/45 R17",
    "product_id": 952,
    "force_model": "gpt-4o-mini"
  }'
```

**Используется:** `gpt-4o-mini` (быстрая генерация)  
**Стоимость:** средняя между DeepSeek и GPT-4o

---

### 4. С дополнительными параметрами и ссылками

```bash
curl -X POST http://localhost:3000/api/v1/generate_seo_text \
  -H "Content-Type: application/json" \
  -d '{
    "tire_description": "<p>Высококачественные зимние шины Bridgestone Blizzak-6</p>",
    "brand": "Bridgestone",
    "model": "Blizzak-6",
    "season": "зимние",
    "language": "ru",
    "size": "225/45 R17",
    "product_id": 952,
    "load_index": "99",
    "speed_index": "H",
    "seo_requirements": "Ключевые слова: Bridgestone Blizzak-6, зимние шины 225/45 R17",
    "max_tokens": 2500,
    "links": [
      {
        "brand": "/shiny/bridgestone/",
        "model": "/shiny/bridgestone/blizzak-6/",
        "brand_sezon": "/shiny/zimnie/bridgestone/"
      }
    ]
  }'
```

---

## 📊 Ответ API

### Успешный ответ:

```json
{
  "success": true,
  "seo_text": "<h2>Зимние шины Bridgestone Blizzak-6 225/45 R17</h2>...",
  "product_id": 952,
  "metadata": {
    "brand": "Bridgestone",
    "model": "Blizzak-6",
    "season": "зимние",
    "language": "ru",
    "size": "225/45 R17",
    "load_index": "99",
    "speed_index": "H",
    "ai_model": "deepseek-chat (default)",
    "generated_at": "2025-10-17T10:30:00Z"
  }
}
```

### Ошибка:

```json
{
  "success": false,
  "error": "Ошибка генерации текста"
}
```

---

## 🎯 Доступные модели

### DeepSeek (рекомендуется):
- **`deepseek-chat`** - универсальная модель (по умолчанию)
  - Экономия: 90%
  - Качество: на уровне GPT-4
  - Скорость: быстрая

### OpenAI (для сравнения):
- **`gpt-4o`** - мощная модель
  - Стоимость: $2.50/$10.00 за 1M токенов
  - Качество: отличное
  - Скорость: средняя

- **`gpt-4o-mini`** - быстрая модель
  - Стоимость: $0.15/$0.60 за 1M токенов
  - Качество: хорошее
  - Скорость: очень быстрая

---

## 💰 Сравнение стоимости

Для SEO-текста (~2000 input + ~3000 output токенов):

| Модель | Стоимость | Когда использовать |
|--------|-----------|-------------------|
| **deepseek-chat** | **$0.0037** | **Всегда (по умолчанию)** ✅ |
| deepseek-chat (льготные часы) | $0.0019 | Batch-обработка ночью 🔥 |
| gpt-4o | $0.0350 | Критичный контент |
| gpt-4o-mini | $0.0021 | Быстрая генерация |

---

## 🔄 Логика выбора модели

```
1. Параметр force_model указан?
   ├─ Да → Используется указанная модель
   └─ Нет → DeepSeek по умолчанию
   
2. DeepSeek доступен?
   ├─ Да → Используется DeepSeek
   └─ Нет → Автоматический fallback на OpenAI
   
3. Превышен лимит затрат?
   └─ Да → Fallback на gpt-4o-mini
```

---

## 📱 Примеры на разных языках

### JavaScript (fetch):

```javascript
const response = await fetch('http://localhost:3000/api/v1/generate_seo_text', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    tire_description: '<p>Высококачественные зимние шины</p>',
    brand: 'Bridgestone',
    model: 'Blizzak-6',
    season: 'зимние',
    language: 'ru',
    size: '225/45 R17',
    product_id: 952,
    force_model: 'gpt-4o' // опционально
  })
});

const data = await response.json();
console.log(data.seo_text);
console.log('Использована модель:', data.metadata.ai_model);
```

### Python (requests):

```python
import requests

response = requests.post(
    'http://localhost:3000/api/v1/generate_seo_text',
    json={
        'tire_description': '<p>Высококачественные зимние шины</p>',
        'brand': 'Bridgestone',
        'model': 'Blizzak-6',
        'season': 'зимние',
        'language': 'ru',
        'size': '225/45 R17',
        'product_id': 952,
        'force_model': 'deepseek-chat'  # опционально
    }
)

data = response.json()
print(data['seo_text'])
print(f"Использована модель: {data['metadata']['ai_model']}")
```

### PHP:

```php
<?php
$ch = curl_init('http://localhost:3000/api/v1/generate_seo_text');

curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
    'tire_description' => '<p>Высококачественные зимние шины</p>',
    'brand' => 'Bridgestone',
    'model' => 'Blizzak-6',
    'season' => 'зимние',
    'language' => 'ru',
    'size' => '225/45 R17',
    'product_id' => 952,
    'force_model' => 'gpt-4o' // опционально
]));

$response = curl_exec($ch);
$data = json_decode($response, true);

echo $data['seo_text'];
echo "Использована модель: " . $data['metadata']['ai_model'];
?>
```

---

## 🎯 Рекомендации

### ✅ Используйте БЕЗ `force_model`:
- Обычная генерация контента
- Массовое производство текстов
- Экономия бюджета (90% дешевле)

### ⚡ Используйте `force_model: "gpt-4o-mini"`:
- Быстрая генерация
- Тестирование
- Средний бюджет

### 🎨 Используйте `force_model: "gpt-4o"`:
- Критичный контент
- A/B тестирование качества
- Премиум контент

---

## 🔍 Отладка

### Проверка используемой модели:

Модель всегда возвращается в ответе:

```json
{
  "metadata": {
    "ai_model": "deepseek-chat (default)"
  }
}
```

### Логи:

```bash
tail -f log/development.log | grep -i "model"
```

Вы увидите:
```
Using default DeepSeek model: deepseek-chat
# или
Using forced model: gpt-4o
# или
DeepSeek client not available, falling back to OpenAI
```

---

## ⚠️ Важные примечания

1. **Без параметра `force_model`:** Используется DeepSeek (экономия 90%)
2. **С параметром `force_model`:** Используется указанная модель
3. **DeepSeek недоступен:** Автоматический fallback на OpenAI
4. **Превышен лимит:** Автоматический переход на gpt-4o-mini

---

## 💡 Примеры реальных сценариев

### Сценарий 1: Массовая генерация (экономия)

```bash
# 1000 товаров БЕЗ force_model = DeepSeek
for i in {1..1000}; do
  curl -X POST http://localhost:3000/api/v1/generate_seo_text \
    -d "brand=Michelin&model=Pilot&size=225/45R17&..."
done

# Экономия: ~$3.15/день = $94/месяц
```

### Сценарий 2: A/B тестирование качества

```bash
# Группа A: DeepSeek
curl -d "brand=Michelin&..." \
  http://localhost:3000/api/v1/generate_seo_text

# Группа B: GPT-4o
curl -d "brand=Michelin&force_model=gpt-4o&..." \
  http://localhost:3000/api/v1/generate_seo_text

# Сравниваем конверсию
```

### Сценарий 3: Премиум контент

```bash
# Важные страницы = GPT-4o
curl -d "brand=Michelin&product_id=1&force_model=gpt-4o&..." \
  http://localhost:3000/api/v1/generate_seo_text

# Обычные страницы = DeepSeek
curl -d "brand=Michelin&product_id=2&..." \
  http://localhost:3000/api/v1/generate_seo_text
```

---

## 📊 Мониторинг использования

### Статистика моделей:

```bash
rails ai_reviews:status
```

Покажет:
```
=== Использование моделей ===
deepseek-chat: 950 запросов, $3.51
gpt-4o: 50 запросов, $1.75
```

---

## ✅ Итог

- **По умолчанию (БЕЗ `force_model`):** DeepSeek - оптимально в 99% случаев
- **С `force_model`:** Полный контроль для специальных задач
- **Автоматический fallback:** Надежность при любых проблемах

**Рекомендация:** Используйте БЕЗ `force_model` для максимальной экономии! 💎

