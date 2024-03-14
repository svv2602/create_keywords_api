require 'json'

path = '/home/user/RubymineProjects/workspace_api/create_keywords_api/lib/template_texts/'
file_path = path + 'data.txt'
texts = {}
current_text = {}
current_key = ''
index = 1

File.foreach(file_path) do |line|
  line = line.strip

  if line.include?(':')
    current_key, value = line.split(':').map(&:strip)
    if current_key == 'TextBody'
      current_text[current_key] = [value]
    else
      current_text[current_key] = value
    end
  elsif line.empty? && !current_text.empty?
    texts["Block_#{index}"] = current_text
    current_text = {}
    index += 1
  elsif !current_key.empty?
    current_text[current_key] << line
  end

end

texts["Block_#{index}"] = current_text unless current_text.empty?

File.open(path + 'data.json', 'w') do |f|
  f.write(JSON.pretty_generate(texts))
end