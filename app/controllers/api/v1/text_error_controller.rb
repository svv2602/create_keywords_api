class Api::V1::TextErrorController < ApplicationController
  include StringProcessing
  include StringErrorsProcessing
  def text_line
    # test_url = 'https://prokoleso.ua/shiny/letnie/taurus/w-175/h-70/r-13/'
    # url = CGI::unescape(test_url) # возвращает URL обратно в незакодированном виде
    # GET /text_line?url=https%3A%2F%2Fprokoleso.ua%2Fshiny%2Fw-175%2Fh-70%2Fr-13%2F
    # url = CGI::unescape(params[:url]) # возвращает URL обратно в незакодированном виде

    result = arr_url_result_str

    render json: { result: result }
    puts result
  end

end