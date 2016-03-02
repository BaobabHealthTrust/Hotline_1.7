
class EncounterType < ActiveRecord::Base
  self.table_name = "encounter_type"
  include Openmrs 
  default_scope { where(retired: 0) }

	#has_many :encounters
  has_one :encounters, class_name: "Encounter", foreign_key: "encounter_type"

end
