class Role < ActiveRecord::Base
  self.table_name = "role"
  include Openmrs
  
end
