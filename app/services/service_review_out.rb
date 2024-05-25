# app/services/service_review_out.rb
require_relative '../../app/services/dictionaries/const_reviews'
module ServiceReviewOut
  def names_auto(record)
    result =""
    if record
      auto_brand = record.kit.model.brand.name
      auto_model = record.kit.model.name
      auto_year = record.kit.year
    end
    result += "#{auto_brand} #{auto_model} #{auto_year} | "
    result
  end

  def random_array_with_average(type_review, type_season)
    # результатом является массив с оценками для легковых шин!!!
    # type_review: 1 - положительный, 2 - нейтральный, 3 - негативный
    # type_season: 1 - летние легковые шины, другое значение для остальных шин
    number_of_ratings = type_season == 1 ? 4 : 6
    n = values_for_review_type(type_review)
    array = []
    number_of_ratings.times do |i|
      num = (rand(n..10.0) * 2).round / 2.0
      el = i % 2 == 0 ? num : 2 * n - array[i - 1]
      if el <= 9 && el >= 2.5
        el += 0.5 * rand(1..10) % 2 == 0 ? -1 : 1 if rand(1..10) % 2 == 0
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
             when 0
               rand(6..8)
             when -1
               rand(3..6)
             else
               10
             end

    result.to_f
  end

  def arr_values_for_review_type(arr)
    str = ''
    arr.each do |el|
      str += "_"
      str += case el
               when 7..10
                 1
               when 5..8
                 0
               when 0..5
                 -1
               else
                 -1
             end.to_s

    end

    str
  end

  def value_field_control(season_param,type_review_param, arr_values)
    # летние_положительный_1_1_1_1_nil_nil
    season = case season_param
             when 1
               "летние"
             when 2
               "зимние"
             when 3
               "всесезонные"
             end

    type_review = case type_review_param
                  when 1
                    "положительный"
                  when -1
                    "негативный"
                  when 0
                    "нейтральный"
                  end

    rating_string = arr_values_for_review_type(arr_values)

    str_nil = "_nil_nil"

    result =  season + "_" + type_review +  rating_string
    result += str_nil if season_param == 1
    result

  end



end


