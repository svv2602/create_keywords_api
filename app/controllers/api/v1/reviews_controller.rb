# app/controllers/api/v1/reviews_controller.rb

class Api::V1::ReviewsController < ApplicationController
  include ServiceReview

  def my_test
    result = generating_texts_and_writing_to_tables

    # result = additional_information_for_text_generation("зимние", "негативный")
    # result =  str_additional_information_for_text_generation
    puts "#{result.inspect} " # #{result.inspect}
    render json: { result: result }
  end

  def fill_table_review
    result = generating_records_and_writing_to_table_review
    puts "#{result.inspect} " # #{result.inspect}
    render json: { result: result }
  end

end