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

def validate_date(date)
	formats = ['%d-%m-%y', '%Y-%m-%dT%H:%M:%S%z', '%Y-%m-%d %H:%M:%S %z']
	formats.each do |format|
		begin
			return true if Date.strptime(date, format)
		rescue
		end
	end
	raise InvalidInputError.new("Date you have entered is invalid, please enter a valid date")
end

def add_pci_child
	#xlsx = Roo::Spreadsheet.open("#{Rails.root}/app/assets/data/CCPF_PCI_Data_Child.xlsx")
	xlsx = Roo::Excelx.new("#{Rails.root}/app/assets/data/CCPF_PCI_Data_Child.xlsx")
	i = 0
	xlsx.each_row_streaming(pad_cells: true) do |row|
		puts row.inspect and return # Array of Excelx::Cell objects
		i = i + 1
		
		# rows before row 4 are header related.
		if i >= 5 and !row[0].blank? and
			# create person
			person = Person.new
			person.gender = row[7].value
			birthdate = row[9].value.to_datetime.strftime('%Y-%m-%d')
			next if validate_date(birthdate) != true
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
			puts "Person #{i-4} creation: Ok"
			return "Creating data successfully completed." if row[0].nil?
		end
	end
end

add_pci_child
