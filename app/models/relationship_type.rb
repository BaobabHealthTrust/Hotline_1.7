class RelationshipType < ActiveRecord::Base
  self.table_name = "relationship_type"
  include Openmrs
  
end
