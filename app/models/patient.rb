class Patient < ActiveRecord::Base
  self.table_name ='patient'
  include Openmrs

  default_scope { where(voided: 0) }

  has_one :person, class_name: "Person", foreign_key: "person_id"

  def nutrition_module
  	patient_age = self.person.age
  	category  = "Group 6"
  	female = self.person.gender.scan(/F/i).length > 0 rescue false

  	recent_preg_obs =  Encounter.find_by_sql(
  		"SELECT  * FROM encounter e 
  		INNER JOIN obs o ON e.patient_id = o.person_id
  		WHERE e.voided = 0 AND DATEDIFF(DAY, DATE(e.encounter_datetime), CURDATE()) <= 270
  		AND e.encounter_type IN (SELECT encounter_type_id FROM encounter_type 
  			WHERE name IN ('PREGNANCY STATUS', 'MATERNAL HEALTH SYMPTOMS'))
		AND ((o.value_coded IN (SELECT concept_id FROM concept_name WHERE name IN ('PREGNANT',
			'VAGINAL BLEEDING DURING PREGNANCY', 'FEVER DURING PREGNANCY', 'No Fetal Movements'))) 
  				OR (o.value_text IN ('PREGNANT',
			'VAGINAL BLEEDING DURING PREGNANCY', 'FEVER DURING PREGNANCY', 'No Fetal Movements'))) "
  			)
  		
  	pregnant_obs =  ""
	if !recent_preg_obs.blank? 
		category = "Group 1"
	elsif female && patient_age >= 14 && patient_age < 50 
		category = "Group 2"
	end
  end



end
