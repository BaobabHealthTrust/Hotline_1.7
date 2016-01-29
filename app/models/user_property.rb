class UserProperty < ActiveRecord::Base
  self.table_name ='user_property'

  belongs_to :user 
end
