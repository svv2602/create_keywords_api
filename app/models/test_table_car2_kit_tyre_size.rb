class TestTableCar2KitTyreSize < ApplicationRecord
  self.primary_key = 'id'
  belongs_to :tyres,
             class_name: 'TestTableCar2Kit',
             foreign_key: :kit

end