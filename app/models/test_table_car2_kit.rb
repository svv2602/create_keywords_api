class TestTableCar2Kit < ApplicationRecord
  self.primary_key = 'id'

  belongs_to :model,
             class_name: 'TestTableCar2Model',
             foreign_key: :model

  has_many :tyres,
           class_name: 'TestTableCar2KitTyreSize',
           foreign_key: :kit

  has_many :disks,
           class_name: 'TestTableCar2KitDiskSize',
           foreign_key: :kit



end