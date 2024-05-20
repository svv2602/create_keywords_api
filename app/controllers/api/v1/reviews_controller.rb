# app/controllers/api/v1/reviews_controller.rb

class Api::V1::ReviewsController < ApplicationController
  include ServiceReview

  def my_test
    result = generate_review
    puts "#{result.inspect} " # #{result.inspect}
    render json: { result: result }
  end



end