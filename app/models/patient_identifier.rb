class PatientIdentifier < ActiveRecord::Base
  self.table_name = "patient_identifier"
  include Openmrs

  default_scope { where(voided: 0) }

  belongs_to :patient
  
end
