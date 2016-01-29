class PersonAddress < ActiveRecord::Base
  self.table_name ='person_address'
  include Openmrs 

  default_scope { where(voided: 0) }

  belongs_to :person
  
end
