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
				
				# create obs for 'PURPOSE OF CALL' encounter to state this person as a caller for reporting purposes
				person_obs = Observation.new
				person_obs.person_id = person_id
				person_obs.encounter_id = 11
				person_obs.obs_datetime = Time.now.strftime('%Y-%m-%d %H:%m:%S')
				person_obs.location_id = 35002
				person_obs.comments = 1 # to set the observation as 1 time caller
				person_obs.creator = 1
				person_obs.save!
				
				puts "Person #{i-4} creation: Ok"
			else
				next
			end
			return "Creating data successfully completed." if row[0].nil?
		end
	end
end

add_pci_child
