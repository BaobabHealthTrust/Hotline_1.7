##################################################################################
#                                                                                #
# Created by: Jacob Mziya (BHT Software Developer)                               #
# Description: To load PCI Child Data into Hotline CCPF system                   #
# Created on: February 13th, 2017                                                #
# Plugins: roo                                                                   #
#                                                                                #
##################################################################################

require 'roo'
require 'date'

def birthdate_check(received_date)
	valid_date = received_date.to_datetime.strftime('%Y-%m-%d') rescue false
	return valid_date
end

def add_pci_child
	#xlsx = Roo::Spreadsheet.open("#{Rails.root}/app/assets/data/CCPF_PCI_Data_Child.xlsx")
	xlsx = Roo::Excelx.new("#{Rails.root}/app/assets/data/CCPF_PCI_Data_Child.xlsx")
	i = 0
	xlsx.each_row_streaming(pad_cells: true) do |row|
		# and return # Array of Excelx::Cell objects
		i = i + 1
		
		# rows before row 4 are header related.
		if i >= 5 and !row[0].blank?
			# create person
			person = Person.new
			person.gender = row[7].value
			#birthdate = row[9].value.to_datetime.strftime('%Y-%m-%d')
			birthdate = birthdate_check(row[9].value)
			if birthdate != false
				person.birthdate = birthdate
				person.creator = 1
				person.save!
				
				# get newly created person
				person_id = Person.last.id
				
				# create new person's name
				person_name = PersonName.new
				person_name.person_id = person_id
				person_name.given_name = row[4].value
				person_name.family_name = row[5].value
				person_name.creator = 1
				person_name.save!
				
				# create new person's name code
				person_name_code = PersonNameCode.new
				person_name_code.given_name_code = row[4].value.soundex
				person_name_code.family_name_code = row[5].value.soundex
				person_name_code.person_name_id = person_id
				person_name_code.save!
				
				# create new person's addresses
				person_address = PersonAddress.new
				person_address.person_id = person_id
				person_address.address2 = row[0].value
				person_address.county_district = row[1].value
				person_address.neighborhood_cell = row[3].value
				person_address.township_division = row[11].value
				person_address.save!
				
				# create new person's attributes
				# (Nearest Health Facility
				# Occupation
				# Phone Number)
				attributes = [1,6,14]
				attributes.each do |attribute_type|
					person_attribute = PersonAttribute.new
					person_attribute.person_id = person_id
					person_attribute.person_attribute_type_id = attribute_type.to_i
					
					if attribute_type.to_i == 1
						# phone Number
						person_attribute.value = row[16].value || 'NULL'
					elsif attribute_type.to_i == 6
						# occupation
						person_attribute.value = row[8].value || 'NULL'
					elsif attribute_type.to_i == 14
						# nearest health facility
						person_attribute.value = row[15].value || 'NULL'
					end
					
					person_attribute.creator = 1
					person_attribute.save!
				end
				
				# create person as patient
				patient = Patient.new
				patient.patient_id = person_id
				patient.save!
				
				# create patient identifier
				avr_identifier_type = PatientIdentifierType.find_by_name('IVR access code')
				patient_avr = PatientIdentifier.new
				patient_avr.identifier = PatientService.next_avr_number
				patient_avr.identifier_type = avr_identifier_type.id
				patient_avr.patient_id = person_id
				patient_avr.save!
				
				# create 'REGISTRATION' encounter
				reg_enc = Encounter.new
				reg_enc.encounter_type = 2
				reg_enc.patient_id = person_id
				reg_enc.provider_id = 1
				reg_enc.location_id = 35002
				reg_enc.encounter_datetime = Time.now.strftime('%Y-%m-%d %H:%m:%S')
				reg_enc.creator = 1
				reg_enc.save!
				
				# create 'PURPOSE OF CALL' encounter
				poc_enc = Encounter.new
				poc_enc.encounter_type = 11
				poc_enc.patient_id = person_id
				poc_enc.provider_id = 1
				poc_enc.location_id = 35002
				poc_enc.encounter_datetime = Time.now.strftime('%Y-%m-%d %H:%m:%S')
				poc_enc.creator = 1
				poc_enc.save!
				
				poc_enc_id = Encounter.last.id
				
				# create obs for 'PURPOSE OF CALL' encounter to state this person as a caller for reporting purposes
				person_obs = Observation.new
				person_obs.person_id = person_id
				person_obs.encounter_id = poc_enc_id
				person_obs.concept_id = 125
				person_obs.value_text = 'Maternal and child health - general advice'
				person_obs.obs_datetime = Time.now.strftime('%Y-%m-%d %H:%m:%S')
				person_obs.location_id = 35002
				person_obs.comments = 1 # to set the observation as 1 time caller
				person_obs.creator = 1
				person_obs.save!
				
				puts "Person #{i-4} creation: Ok"
			else
				Kernel.system ('mkdir lib/migration_logs')
				log_text = "Skipped #{row[5].value}, #{row[4].value} :Invalid Date of Birth format."
				log_file = "#{Rails.root}/lib/migration_logs/pci_child.txt"
				command = "echo #{log_text} >> #{log_file}"
				if Kernel.system (command)
					Kernel.system ("echo #{log_text}")
				end
				next
			end
			return 'Creating data successfully completed.' if row[0].nil?
		end
	end
end

add_pci_child
