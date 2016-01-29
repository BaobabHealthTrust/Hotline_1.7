class PersonAttribute < ActiveRecord::Base
  self.table_name ='person_attribute'
  include Openmrs

  default_scope { where(voided: 0) }

  belongs_to :person_attribute_type
  belongs_to :person
end
