class TestTableCar2Brand < ApplicationRecord
  self.primary_key = 'id'
  has_many :model, class_name: 'TestTableCar2Model', foreign_key: 'brand'
end