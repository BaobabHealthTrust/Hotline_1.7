class UserRole < ActiveRecord::Base
  self.table_name ='user_role'

  belongs_to :user 
end
