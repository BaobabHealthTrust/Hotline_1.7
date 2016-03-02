class ConceptNumeric < ActiveRecord::Base
  self.table_name = "concept_numeric"
  include Openmrs

	belongs_to :concept 


end
