class ConceptSet < ActiveRecord::Base
  self.table_name = "concept_set"
  include Openmrs

  belongs_to :concept, class_name: "Concept", foreign_key: "concept_set_id"


end
