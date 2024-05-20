class Api::V1::ReviewsController < ApplicationController
  include ServiceReview

  def my_test
    result = random_array_with_average(2,1)
    puts "Все сделано! ===== #{result.inspect} " # #{result.inspect}
    render json: { result: result }
  end



end