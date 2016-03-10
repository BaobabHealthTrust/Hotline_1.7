class Relationship < ActiveRecord::Base
  self.table_name = "relationship"
  include Openmrs
  
end
