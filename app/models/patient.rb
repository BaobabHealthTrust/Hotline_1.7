class Patient < ActiveRecord::Base
  self.table_name ='patient'
  include Openmrs

  default_scope { where(voided: 0) }

  has_one :person, class_name: "Person", foreign_key: "person_id"


end
