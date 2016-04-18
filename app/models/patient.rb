class Patient < ActiveRecord::Base
  self.table_name ='patient'
  include Openmrs

  default_scope { where(voided: 0) }

  has_one :person, class_name: "Person", foreign_key: "person_id"

  def nutrition_module
  	patient_age = self.person.age
  	temp_date =  DateTime.new(0000, 6, 1)
  	six_months = temp_date.month.to_i

  	category  = "Group 6"
  	female = self.person.gender.scan(/F/i).length > 0 rescue false

  	recent_preg_obs =  Encounter.find_by_sql(
  		"SELECT  * FROM encounter e 
  		INNER JOIN obs o ON e.patient_id = o.person_id
  		WHERE e.voided = 0 AND TIMESTAMPDIFF(DAY, DATE(e.encounter_datetime), CURDATE()) <= 270
  		AND e.encounter_type IN (SELECT encounter_type_id FROM encounter_type 
  			WHERE name IN ('PREGNANCY STATUS', 'MATERNAL HEALTH SYMPTOMS'))
		AND ((o.value_coded IN (SELECT concept_id FROM concept_name WHERE name IN ('PREGNANT',
			'VAGINAL BLEEDING DURING PREGNANCY', 'FEVER DURING PREGNANCY', 'Water breaks', 'No Fetal Movements'))) 
  				OR (o.value_text IN ('PREGNANT',
			'VAGINAL BLEEDING DURING PREGNANCY', 'FEVER DURING PREGNANCY', 'Water breaks', 'No Fetal Movements'))) "
  			)
  	
  	pregnant_obs =  ""
  	
    if !recent_preg_obs.blank? && female
      category = "Group 2"
    elsif female && patient_age >= 14 && patient_age < 50
      category = "Group 1"
    elsif patient_age >= 14
      category = "Group 3"
    elsif patient_age < six_months
      category = "Group 4"
    elsif patient_age > six_months && patient_age <= 2
      category = "Group 5"
    elsif patient_age > 2 && patient_age < 5
      category = "Group 6"
    elsif patient_age > 5 && patient_age < 14
      category = "Group 7"
    end
  end

  def current_guardian(guardian_id=nil)
    if guardian_id
      return Person.find(guardian_id) rescue nil
    end

    #search for guardian created same day
    rel_type = RelationshipType.where(:a_is_to_b => 'Patient', :b_is_to_a => 'Guardian').first
    rel = Relationship.where(:relationship => rel_type.id, :person_a => self.patient_id).order("date_created DESC").first

    if rel
      return Person.find(rel.person_b) if rel.date_created.to_date == Date.today
    end
    return nil
  end
end
