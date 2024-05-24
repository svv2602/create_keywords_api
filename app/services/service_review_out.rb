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
end


