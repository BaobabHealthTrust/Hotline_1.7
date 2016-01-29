class LocationTag < ActiveRecord::Base
  self.table_name = "location_tag"
  include Openmrs

  has_many :location_tag_map, foreign_key: "location_tag_id"

end
