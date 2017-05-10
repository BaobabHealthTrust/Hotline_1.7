##################################################################################
#                                                                                #
# Created by: Jacob Mziya (BHT Software Developer)                               #
# Description: To load PCI Women Data into Hotline CCPF system                   #
# Created on: February 13th, 2017                                                #
# Plugins: roo                                                                   #
#                                                                                #
##################################################################################

require 'roo'
require 'date'

def birthdate_check(received_date)
	#raise received_date.inspect and return if received_date == 'Tue, 07 Nov 1989'
	if received_date.to_s.include? '/'
		
		date_check = received_date.split('/')
		received_year = date_check[2].to_i
		received_month = date_check[1].to_i
		received_day = date_check[0].to_i
		
		if received_year > 9999 || received_month > 12 || received_day > 31
			valid_date = false
		else
			if received_year < 99
				received_year = "19#{received_year}"
			elsif received_year == 00
				received_year = '2000'
			end
			received_date = "#{received_day}/#{received_month}/#{received_year}"
			valid_date = received_date.to_datetime.strftime('%Y-%m-%d') rescue false
		end
	else
		valid_date = false
	end
	
	return valid_date
end

def add_pci_women
	# load CSV File
	#xlsx = Roo::Spreadsheet.open("#{Rails.root}/app/assets/data/CCPF_PCI_Data_Child.xlsx")
	xlsx = Roo::Excelx.new("#{Rails.root}/app/assets/data/CCPF_PCI_Data.xlsx")
	i = 0
	xlsx.each_row_streaming(pad_cells: true) do |row|
		# and return # Array of Excelx::Cell objects
		i = i + 1
		
		# rows before row 4 are header related.
		if i >= 5 and !row[0].blank?
			# create person
			person = Person.new
			person.gender = 'Female'
			birthdate = birthdate_check(row[10].value) rescue nil
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
						if !person_attribute.value.blank?
							person_attribute.value = row[17].value
						else
							person_attribute.value = 'NA'
						end
					elsif attribute_type.to_i == 6
						# occupation
						if !person_attribute.value.blank?
							person_attribute.value = row[7].value
						else
							person_attribute.value = 'NA'
						end
					elsif attribute_type.to_i == 14
						# nearest health facility
						if !person_attribute.value.blank?
							person_attribute.value = row[16].value
						else
							person_attribute.value = 'NA'
						end
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
				
				# create obs for 'PREGNANCY STATUS' encounter to state this person as a caller for reporting purposes
				person_obs = Observation.new
				person_obs.person_id = person_id
				person_obs.encounter_id = 9
				person_obs.obs_datetime = Time.now.strftime('%Y-%m-%d %H:%m:%S')
				person_obs.location_id = 35002
				person_obs.comments = 1 # to set the observation as 1 time caller
				person_obs.creator = 1
				person_obs.save!
				
				puts "Person #{i-4} creation: Ok"
			else
				Kernel.system ('mkdir lib/migration_logs')
				log_text = "Skipped #{row[5].value rescue 'NA'}, #{row[4].value rescue 'NA'} :Invalid Date of Birth format."
				log_file = "#{Rails.root}/lib/migration_logs/pci_women.txt"
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

add_pci_women