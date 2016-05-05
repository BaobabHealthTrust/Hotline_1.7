class Person < ActiveRecord::Base
  self.table_name ='person'
  include Openmrs 

  default_scope { where(voided: 0) }

  has_one :user
  has_one :patient, class_name: "Patient", foreign_key: "patient_id"
	has_many :person_names
	has_many :person_addresses
  has_many :person_attributes

  def age(today = Date.today)
    #((Time.now - self.birthdate.to_time)/1.year).floor
    # Replaced by Jeff's code which better accounts for leap years

    return nil if self.birthdate.nil?

    patient_age = (today.year - self.birthdate.year) + ((today.month - self.birthdate.month) + ((today.day - self.birthdate.day) < 0 ? -1 : 0) < 0 ? -1 : 0)
   
    birth_date = self.birthdate
    estimate = self.birthdate_estimated
    if birth_date.month == 7 and birth_date.day == 1 and estimate == 1 and Time.now.month < birth_date.month and self.date_created.year == Time.now.year
       return patient_age + 1
    else
       return patient_age
    end     
  end


  def name
    person_name = self.person_names.last rescue (return nil)
    "#{person_name.given_name} #{person_name.family_name}"
  end

end
