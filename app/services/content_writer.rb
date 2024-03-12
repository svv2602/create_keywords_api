# app/services/content_writer.rb

class ContentWriter
  MODEL = 'gpt-3.5-turbo'

  def initialize
    @client = OpenAI::Client.new
  end

  def write_draft_post(prompt, max_tokens)
    # prompt = "Write a #{max_tokens} word blogpost about '#{title}'."
    @client.chat(
      parameters: {
        model: MODEL,
        messages: [
          { role: "system",
            #content: "You are a world class copywriter"
            content: 'Вы копирайтер мирового уровня. Пожалуйста, создайте SEO-текст с заголовками, микроразметкой и HTML-тегами.'
          },

          { role: "system",
            content: "Текст должен быть на русском языке"
            # content: "Your output is always correctly formatted markdown"
            # content: 'Текст должен содержать информацию о летних шинах 205/55 R16 и ключевые слова: Киев, купить шины, резина, лето, летние, лучшие.'
          },
          { role: "user", content: prompt }
        ],
        temperature: 0.8,
        # Temperature (температура): Можно установить значение около 0.5-0.7, чтобы получить
        # более консервативные и ожидаемые ответы. Это поможет избежать слишком экспрессивных
        # или неожиданных фраз.
        max_tokens: max_tokens,
        top_p: 0.9,
        #Top p: Рекомендуется использовать значение около 0.9, чтобы модель могла выбирать
        # наиболее вероятные следующие слова, исходя из распределения вероятностей,
        # что способствует генерации более качественного текста.
        frequency_penalty: 0.4,
        # Frequency Penalty (штраф за частоту): Можно установить значение около 0.2-0.5,
        # чтобы умеренно контролировать повторяемость ключевых слов или фраз в тексте.
        # Это поможет избежать пересыщения текста ключевыми словами и обеспечит его естественность.
        presence_penalty: 0.3
        # Presence Penalty (штраф за присутствие):
        # Также можно установить значение около 0.2-0.5, чтобы стимулировать разнообразие лексики
        # в тексте и избежать излишнего повторения слов или фраз.
      }
    )
  end

  def write_seo_text(prompt, max_tokens)
    # prompt = "Write a #{max_tokens} word blogpost about '#{title}'."
    @client.chat(
      parameters: {
        model: MODEL,
        messages: [
          { role: "system",
            content: 'Вы копирайтер мирового уровня, который делает делает свою работу качественно, согласно техзаданию'
          },
          { role: "user", content: prompt }
        ],
        # temperature: 0.5,
        max_tokens: max_tokens,
        # top_p: 0.9,
        # frequency_penalty: 0.4,
        # presence_penalty: 0.3
      }
    )
  end



end