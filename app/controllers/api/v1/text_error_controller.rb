
class Api::V1::TextErrorController < ApplicationController
  def text_line
    result = "СТРОКА"
    render json: { result: result }
    puts result
  end


end