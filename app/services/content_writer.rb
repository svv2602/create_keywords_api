# app/services/content_writer.rb

class ContentWriter
  MODEL = 'gpt-3.5-turbo'

  def initialize
    @client = OpenAI::Client.new
  end

  def write_draft_post(title)
    prompt = "Write a 1000 word blogpost about '#{title}'."
    @client.chat(
      parameters: {
        model: MODEL,
        messages: [
          { role: "system", content: "You are a world class copywriter" },
          { role: "system", content: "Your output is always correctly formatted markdown" },
          { role: "user", content: prompt }
        ]
      }
    )
  end
end