require "composite_primary_keys"

class RolePrivilege < ActiveRecord::Base
  self.table_name = "role_privilege"

  include Openmrs

  belongs_to :role #, :foreign_key => :role # no default scope
  belongs_to :privilege #, :foreign_key => :privilege # no default scope
end
