class TestTableCar2Model < ApplicationRecord
  self.primary_key = 'id'
  belongs_to :brand, class_name: 'TestTableCar2Brand', foreign_key: 'brand'
end