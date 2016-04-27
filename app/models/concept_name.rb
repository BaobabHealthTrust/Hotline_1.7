class ConceptName < ActiveRecord::Base
  self.table_name = "concept_name"
  include Openmrs

  default_scope { where(voided: 0) }

	belongs_to :concept, :class_name => "Concept", :foreign_key => 'concept_id'

end
