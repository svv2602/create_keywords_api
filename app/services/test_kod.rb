# app/services/test_kod.rb
require_relative 'service_review'

class TestKod
  include ServiceReview

  def new_arr
    result = topics_array
    result
  end



end

el = TestKod.new
arr = el.new_arr
puts arr.inspect