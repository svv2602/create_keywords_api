# app/services/service_review.rb

module ServiceQuestion

  def random_array_with_average(type_review,type_season)
    # результатом является массив с оценками для легковых шин!!!
    # type_review: 1 - положительный, 2 - нейтральный, 3 - отрицательный
    # type_season: 1 - летние легковые шины, другое значение для остальных шин
    number_of_ratings = type_season ==1 ? 4 : 6
    n = values_for_review_type(type_review)
    array = []
    number_of_ratings.times do |i|
      num = (rand(n..10.0) * 2).round / 2.0
      el = i % 2 == 0 ? num : 2 * n - array[i - 1]
      if el <= 9 && el >=2.5
        el += 0.5 * rand(1..10)%2 == 0 ? -1 : 1 if rand(1..10)%2 == 0
      end
      array[i] = el > 1 ? el : 1.0
    end
    # puts array.inspect
    array
  end

  def values_for_review_type(n)
    result = case n
             when 1
               rand(8..10)
             when 2
               rand(6..8)
             when 3
               rand(3..6)
             else
               10
             end

    result.to_f
  end

end