# Text Completeness Validation

## Описание

Модуль `TextCompletenessValidation` предоставляет методы для проверки целостности сгенерированных AI текстов.

Используется в генераторах SEO текстов для предотвращения возврата обрезанных или неполных HTML-текстов.

## Файл

`app/services/concerns/text_completeness_validation.rb`

## Использование

### Подключение модуля

```ruby
class MyTextGenerator
  include TextCompletenessValidation

  def generate
    text = generate_with_ai(prompt)

    unless text_complete?(text, required_phrases: ['фраза CTA'])
      log_incomplete_text_warning("MyGenerator: #{identifier}")
      return { error: 'Text is incomplete' }
    end

    { text: text }
  end
end
```

## Методы

### `text_complete?(text, options = {})`

Проверяет целостность сгенерированного HTML-текста.

**Параметры:**
- `text` (String) - HTML-текст для проверки
- `options` (Hash) - опциональные параметры:
  - `:required_ending_tag` (String) - тег, которым должен заканчиваться текст (по умолчанию `</p>`)
  - `:required_phrases` (Array<String>) - фразы, которые обязательно должны присутствовать в тексте
  - `:tags_to_check` (Array<String>) - HTML-теги для проверки сбалансированности (по умолчанию `['h2', 'h3', 'h4', 'p', 'ul', 'ol', 'li', 'a']`)

**Возвращает:**
- `true` - если текст полный и корректный
- `false` - если текст обрезан или содержит ошибки

**Проверки:**
1. Текст заканчивается на указанный тег (по умолчанию `</p>`)
2. Текст содержит все обязательные фразы
3. Все HTML-теги сбалансированы (количество открывающих = количеству закрывающих)
4. Текст не заканчивается незавершенным тегом

**Пример:**

```ruby
text = "<h2>Заголовок</h2><p>Текст с призывом оформить заказ.</p>"

# Базовая проверка
text_complete?(text)
# => true

# Проверка с обязательными фразами
text_complete?(text, required_phrases: ['оформить заказ'])
# => true

# Проверка неполного текста
incomplete_text = "<h2>Заголовок</h2><p>Обрезанный те"
text_complete?(incomplete_text)
# => false
```

### `log_incomplete_text_warning(identifier)`

Логирует предупреждение об обрезанном тексте в Rails logger.

**Параметры:**
- `identifier` (String) - идентификатор текста для логирования

**Пример:**

```ruby
log_incomplete_text_warning("Toyota Camry (ru)")
# Запишет в лог: "Generated text appears to be truncated for: Toyota Camry (ru)"
```

## Примеры использования в генераторах

### CarSeoTextGenerator

```ruby
class CarSeoTextGenerator
  include TextCompletenessValidation

  def generate
    response = ContentWriter.new.write_seo_text(prompt, 6000)
    text = clean_html_text(response['choices'][0]['message']['content'])

    cta_phrases = @language == 'ru' ?
      ['оформите заказ онлайн', 'оформіть замовлення онлайн'] :
      ['оформіть замовлення онлайн', 'оформите заказ онлайн']

    unless text_complete?(text, required_phrases: cta_phrases)
      log_incomplete_text_warning("#{@brand} #{@model} (#{@language})")
      return { error: 'Generated text is incomplete' }
    end

    { text: text, ... }
  end
end
```

### SeoTextGenerator

```ruby
class SeoTextGenerator
  include TextCompletenessValidation

  def generate
    response = @content_writer.write_seo_text(prompt, @max_tokens)
    generated_text = response['choices'][0]['message']['content'].strip

    unless text_complete?(generated_text)
      log_incomplete_text_warning("#{@brand} #{@model} #{@size} (#{@language})")
      return nil
    end

    format_generated_text(generated_text)
  end
end
```

## Типичные причины обрезанного текста

1. **Недостаточный max_tokens** - AI не успевает сгенерировать полный текст
2. **Слишком сложный промпт** - слишком много требований или длинный контекст
3. **Временные проблемы с AI API** - таймауты или сбои

## Рекомендации

При обнаружении обрезанного текста:

1. **Увеличить max_tokens** - дать больше места для генерации
2. **Упростить промпт** - уменьшить количество требований
3. **Повторить запрос** - AI может сгенерировать более короткий вариант
4. **Проверить логи** - найти детали ошибки

## Обработка ошибок в контроллерах

### API V1::CarSeoTextsController

```ruby
def generate
  result = generator.generate

  if result[:error]
    render json: { error: result[:error] }, status: :unprocessable_entity
  else
    render json: result
  end
end
```

### API V1::SeoGeneratorController

```ruby
def generate_seo_text
  seo_text = SeoTextGenerator.new(params).generate

  if seo_text
    render json: { success: true, seo_text: seo_text }
  else
    render json: {
      success: false,
      error: 'Generated text is incomplete or validation failed'
    }, status: :unprocessable_entity
  end
end
```

## Связанные файлы

- [app/services/concerns/text_completeness_validation.rb](../app/services/concerns/text_completeness_validation.rb)
- [app/services/car_seo_text_generator.rb](../app/services/car_seo_text_generator.rb)
- [app/services/seo_text_generator.rb](../app/services/seo_text_generator.rb)
- [docs/CAR_SEO_TEXT_API.md](CAR_SEO_TEXT_API.md)
