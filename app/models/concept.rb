class Concept < ActiveRecord::Base
  self.table_name = "concept"
  include Openmrs 

  default_scope { where(retired: 0) }

	has_many :concept_names
	has_one :concept_numeric
  has_many :concept_sets, class_name: "ConceptSet", foreign_key: "concept_id"


end
