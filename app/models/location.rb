class Location < ActiveRecord::Base
  self.table_name = "location"
  include Openmrs

  cattr_accessor :current

end
