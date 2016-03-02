
class Encounter < ActiveRecord::Base
  self.table_name = "encounter"
  include Openmrs
  default_scope { where(voided: 0) }

	belongs_to :patient 
	has_many :observations
  belongs_to :type, class_name: "EncounterType", foreign_key: "encounter_type"


end
