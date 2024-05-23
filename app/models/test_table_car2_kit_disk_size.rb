class TestTableCar2KitDiskSize < ApplicationRecord
  self.primary_key = 'id'
  belongs_to :disks,
             class_name: 'TestTableCar2Kit',
             foreign_key: :kit

end