class PersonName < ActiveRecord::Base
  self.table_name ='person_name'
  include Openmrs 

  default_scope { where(voided: 0) }

  belongs_to :person
  #has_one :person_name_code, :foreign_key => :person_name_id # no default scope

end
