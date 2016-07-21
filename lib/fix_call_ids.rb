

def fix_call_ids

	call_id_concept_id 		= ConceptName.find_by_name("Call ID").concept_id

	starting_encounter_id = ActiveRecord::Base.connection.select_one(
														"SELECT MAX(encounter_id) enc_id FROM obs WHERE concept_id = #{call_id_concept_id} "
													)['enc_id']

	starting_call_id 			= ActiveRecord::Base.connection.select_one(
														"SELECT MAX(value_text) call_id FROM obs WHERE concept_id = #{call_id_concept_id} "
													)['call_id']

	encounters 						= Encounter.find_by_sql(
														"SELECT * FROM encounter WHERE encounter_id > #{starting_encounter_id} ORDER BY encounter_datetime ASC "
													)
	
	call_id  							= (starting_call_id.to_i + 1) || 1
	comment								= 1	
	patient_id 						= encounters.first.patient_id rescue - 1
	
	encounters.each_with_index do |encounter, i|

		new_patient_id 	= encounter.patient_id
		
		new_comment 		= Observation.where(:encounter_id => encounter.encounter_id).last.comments #rescue nil

		#NEXT IF ENCOUNTER IS NOT TAGGED OR PATIENT NOT AVAILABLE
		next if new_patient_id.blank?
				
		unless (comment.to_i == new_comment.to_i && patient_id.to_i == new_patient_id.to_i)	

			call_id = call_id.to_i + 1
			#Create Call Log
			create_call_log(encounter, call_id)
		end	

		create_call_id_ob(encounter, call_id)

		patient_id 	= new_patient_id
 
		comment			= new_comment 
		
	end	
end

def create_call_id_ob(encounter, call_id)

	call_id_concept_id 		= ConceptName.find_by_name("Call ID").concept_id

	Observation.create(
		:person_id => encounter.patient_id,
		:concept_id => 	call_id_concept_id,
		:value_text => call_id,
		:location_id => encounter.location_id,
		:obs_datetime => encounter.encounter_datetime
	)
end

def create_call_log(encounter, call_id)
	
end 

puts ""
fix_call_ids



