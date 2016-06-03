require "bantu_soundex"
def call_fixes

	patients = Patient.all
	call_id_concept_id = ConceptName.find_by_name("Call ID").concept_id
	patients.each do |patient|

		call_ids = Observation.find_by_sql("SELECT value_text FROM obs WHERE concept_id = #{call_id_concept_id} 
								AND person_id = #{patient.patient_id}").map(&:value_text).uniq.sort

		call_ids.each_with_index do |c_id, i|
			encounter_ids = Encounter.find_by_sql(
				"SELECT o.encounter_id FROM obs o WHERE o.value_text = #{c_id} AND o.concept_id = #{call_id_concept_id}"
			).map(&:encounter_id).join(",")

				 ActiveRecord::Base.connection.execute(<<-EOQ)
			UPDATE obs
			SET obs.comments = #{i + 1}
			WHERE obs.person_id = #{patient.patient_id} 
			AND obs.encounter_id IN (#{encounter_ids})
				EOQ
		end
	end
end

def gender_fixes
	ActiveRecord::Base.connection.execute(<<-EOQ)
		UPDATE person
		SET gender = 'F'
		WHERE person.gender IS NULL 		
	EOQ
end

def birthdate_fixes
	ActiveRecord::Base.connection.execute(<<-EOQ)
		UPDATE person
		SET birthdate = '1700-01-01 00:00:00'
		WHERE COALESCE(person.birthdate, '') = '' 		
	EOQ
end

def load_name_codes
	PersonName.all.each do |name|
		code = PersonNameCode.find_by_person_name_id(name.id)
		code = PersonNameCode.new if code.blank?

		code.given_name_code = name.given_name.soundex if !name.given_name.blank?
		code.family_name_code = name.family_name.soundex if !name.family_name.blank?
		code.middle_name_code = name.middle_name.soundex if !name.middle_name.blank?
		code.family_name2_code = name.family_name2.soundex if !name.family_name2.blank?
		code.family_name_suffix_code = name.family_name_suffix.soundex if !name.family_name_suffix.blank?
		code.save
	end
end

puts "Starting fixes for call ids: #{Time.now}"
#call_fixes
puts "Done: #{Time.now}"
puts ""
puts "Skipping gender fixes: #{Time.now}"
#gender_fixes
puts "Done: #{Time.now}"
puts "Generating soundex codes: #{Time.now}"
load_name_codes
puts "Done: #{Time.now}"

puts "Setting default birthdate 1700-01-01: #{Time.now}"
birthdate_fixes
puts "Done: #{Time.now}"




