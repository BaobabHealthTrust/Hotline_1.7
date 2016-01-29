class LocationTagMap < ActiveRecord::Base
  self.table_name = "location_tag_map"
  include Openmrs

  belongs_to :location_tag
  belongs_to :location

end
