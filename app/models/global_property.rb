class GlobalProperty < ActiveRecord::Base
  self.table_name ='global_property'
  include Openmrs

  def self.current_health_center
    Location.find(self.find_by_description('current.health.center').property_value)
  end

end
