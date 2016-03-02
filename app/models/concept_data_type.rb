class ConceptDataType < ActiveRecord::Base
  self.table_name = "concept_datatype"
  include Openmrs

  default_scope { where(retired: 0) }



end
