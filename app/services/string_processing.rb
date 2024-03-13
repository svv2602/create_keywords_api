# app/services/string_processing.rb
module StringProcessing
  def arr_size_name_min(ww, hh, rr, i)
    result = ''

    case i % 5
    when 1
      result = "#{ww} #{hh}r#{rr}"
    when 2
      result = "#{ww}/#{hh} P#{rr}"
    when 3
      result = "#{ww}#{hh} r#{rr}"
    when 4
      result = "#{ww}/#{hh} R#{rr}"
    else
      result = "#{ww} #{hh} #{rr}"
    end
    result
  end

  def replace_size_to_template(str)

    search_size_1 = /\d{3}([ \/.-xXхХ]*| на )\d{2}([ \/.-xXхХ]*| на )(|[ rRpPрР])([ \/.-xXхХ]*)\d{2}([.,]\d{1})?[ \/.-]*[ cCсС]*/
    search_size_2 = /(на |)[ rRpPрР]\d{2}([.,]\d{1})?[ \/.-xXхХ]*[ cCсС]*([ \/.-xXхХ]*| на )\d{3}([ \/.-xXхХ]*| на )\d{2}/
    str.gsub!(search_size_1, " [size] ")
    str.gsub!(search_size_2, " [size] ")
    str

  end

  def template_txt_to_array_and_write_to_json(name_file_out)
    text_array = []
    file_path = Rails.root.join('lib', 'template_texts', 'text')
    file_path_out = Rails.root.join('lib', 'template_texts', name_file_out)

    begin
      File.foreach("#{file_path}.txt") { |line| text_array << line.chomp }
    rescue Errno::ENOENT
      puts "File not found"
      return
    end

    # Запись в файл
    File.write("#{file_path_out}.json", JSON.dump(text_array))
  end

  def read_array_from_json_file(name_file_out)
    file_path_out = Rails.root.join('lib', 'template_texts', name_file_out)
    begin
      json_string = File.read("#{file_path_out}.json")
    rescue Errno::ENOENT
      puts "File not found"
      return []
    end

    array_from_json = JSON.parse(json_string)
    array_from_json
  end
end