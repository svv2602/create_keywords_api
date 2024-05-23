class TestTableCar2Model < ApplicationRecord
  self.primary_key = 'id'
  belongs_to :brand,
             class_name: 'TestTableCar2Brand',
             foreign_key: :brand
  has_many :kits,
           class_name: 'TestTableCar2Kit',
           foreign_key: :model

end