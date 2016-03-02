class ConceptClass < ActiveRecord::Base
  self.table_name = "concept_class"
  include Openmrs

  default_scope { where(retired: 0) }



end
