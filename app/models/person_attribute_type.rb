class PersonAttributeType < ActiveRecord::Base
  self.table_name ='person_attribute_type'
  include Openmrs

  default_scope { where(retired: 0) }

  has_many :person_attributes
end
