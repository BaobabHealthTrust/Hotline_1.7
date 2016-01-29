module Openmrs

  def self.included(base)
    base.class_eval do
      before_create :check_record_complteness_before_creating
      before_save :check_record_complteness_before_updating
    end
  end
 
  def check_record_complteness_before_creating
    self.creator = User.current.id if self.attribute_names.include?("creator") and (self.creator.blank? || self.creator == 0)and User.current != nil
    self.provider_id = User.current.person.id if self.attribute_names.include?("provider_id") and (self.provider_id.blank? || self.provider_id == 0)and User.current != nil
    self.date_created = Time.now if self.attribute_names.include?("date_created")
    self.uuid = ActiveRecord::Base.connection.select_one("SELECT UUID() as uuid")['uuid'] if self.attribute_names.include?("uuid")
  end
  
  def check_record_complteness_before_updating
    self.changed_by = User.current.id if self.attribute_names.include?("changed_by") and (self.creator.blank? || self.creator == 0)and User.current != nil
  end

end
