# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
=begin
	#code to consider for DB Seed metadata1.7
unless Rails.env.production?
  connection = ActiveRecord::Base.connection
  connection.tables.each do |table|
    connection.execute("TRUNCATE #{table}") unless table == "schema_migrations"
  end
   
  # - IMPORTANT: SEED DATA ONLY
  # - DO NOT EXPORT TABLE STRUCTURES
  # - DO NOT EXPORT DATA FROM `schema_migrations`
  sql = File.read('db/openmrs_metadata_1_7.sql')
  statements = sql.split(/;$/)
  statements.pop  # the last empty statement
 
  ActiveRecord::Base.transaction do
    statements.each do |statement|
      connection.execute(statement)
    end
  end
end

# Seeding metadata_1_7 into Application Database
ActiveRecord::Schema.define(version: 0) do
	db_user = YAML::load_file('config/database.yml')[Rails.env]['username']
	db_password = YAML::load_file('config/database.yml')[Rails.env]['password']
	db_database = YAML::load_file('config/database.yml')[Rails.env]['database']

	system "mysql -u #{db_user} -p#{db_password} #{db_database} < db/openmrs_metadata_1_7.sql -v"
end
#end
=end
person = Person.create(:birthdate => Date.today, :birthdate_estimated => 1, :creator => 1)
person_name = PersonName.create(:given_name => "System", :family_name => "Admininistrator",:person_id => person.id)
PersonNameCode.create(:given_name_code => "System".soundex, :family_name_code => "Admininistrator".soundex,:person_name_id => person_name.id)

user = User.create(:username => 'admin',:password => "adminhotline", :creator => 1, :person_id => person.id,:system_id => "admin")

User.current = user

puts "Creating user roles ...."
["System Developer","Provider"].each do |role|
  Role.create(:description => :role => role)
end

puts "Assigning #{user.username} roles ...."
["System Developer","Provider"].each do |role|
  UserRole.create(:user_id => user.id, :role => role)
end


###################################### Creating locations ################################################################
districts = {}
location_tags = []

CSV.foreach("#{Rails.root}/app/assets/data/health_facilities.csv", :headers => true) do |row|
  district_name = row[0] ; facility_name = row[3]
  facility_code = row[2] ; district_code = row[1]
  region = row[4].split(' ')[0] rescue nil
  facility_type = row[5] ; description = row[6] 
  facility_location = row[7] ; latitude = row[8] ; longitude = row[9]
  
  
  next if district_name.blank?   
  location_tags << row[5]
  districts[district_name] = [] if districts[district_name].blank?
  districts[district_name] << [
                                district_code,facility_code, 
                                facility_name,region,facility_type,
                                description,facility_location,
                                latitude, longitude  
                              ] 
end

puts "Creating districts, facilities and location_tag_map ...."
location_tags = location_tags.uniq + ["Region","District","Traditional Authority","Village","Urban","Rural","Facility location"]

location_tags.each do |location|
  description = nil
  description = 'Malawian district' if location == 'District'
  description = 'One of the three regions of Malawi' if location == 'Region'
  description = 'Traditional Authority' if location == 'Traditional Authority'
  description = 'Village' if location == 'Village'
  LocationTag.create(:name => location, :description => description)
end

(districts || {}).each do |district, facilities|
  location = Location.create(:name => district, :description => "Malawian district")
  LocationTagMap.create(location_id: location.id, location_tag_id: LocationTag.where(:name => 'District').first.id)
  region = nil ; district_code = nil

  (facilities || []).each do |facility_attr| 
    facility = Location.create(:name => facility_attr[2],postal_code: facility_attr[1], 
      :description => facility_attr[5],parent_location: location.id,
      latitude: facility_attr[7], longitude: facility_attr[8])

    #Tagging facilit to a facility tag (Clinic/Hospitl/Health center/Central Hosp)
    LocationTagMap.create(location_id: facility.id, location_tag_id: LocationTag.find_by_name(facility_attr[4]).id)
    #Tagging facilit to a facility tag (Urban/Rural)
    LocationTagMap.create(location_id: facility.id, location_tag_id: LocationTag.find_by_name(facility_attr[6]).id)

    region = facility_attr[3] if region.blank?
    district_code = facility_attr[0] if district_code
  end
  #Updating the created district to now have a district_code and a district region
  region_id = LocationTag.find_by_name(region).id rescue LocationTag.create(name: region, description: 'Regions of Malawi')
  location.update_attributes(region: region_id,postal_code: district_code)
end



districts_with_ta_and_villages = {}
CSV.foreach("#{Rails.root}/app/assets/data/districts_with_ta_and_villages.csv", :headers => true).each_with_index do |row, i|
  district_name = row[0].gsub('-',' ').strip ; ta_name = row[1] ; village_name = row[2]
  district = Location.where("t.name = 'District' AND location.name = ?",
             district_name).joins("INNER JOIN location_tag_map m ON m.location_id = location.location_id
             INNER JOIN location_tag t ON t.location_tag_id = m.location_tag_id").first rescue nil
             
  if district.blank?
    new_district = Location.create(name: district_name, description: "A sub district")
    tag_map_id = LocationTag.find_by_name('District').id
    LocationTagMap.create(location_id: new_district.id, location_tag_id: tag_map_id)
    parent_district = Location.find_by_name('Lilongwe') if district_name.match(/Lilongwe/i)
    parent_district = Location.find_by_name('Blantyre') if district_name.match(/Blantyre/i)
    parent_district = Location.find_by_name('Mzimba') if district_name.match(/Mzuzu/i)
    parent_district = Location.find_by_name('Zomba') if district_name.match(/Zomba/i)
    new_district.update_attributes(parent_location: parent_district.id)
    district = new_district
  end
             
  districts_with_ta_and_villages[district.name] = {} if districts_with_ta_and_villages[district.name].blank?
  districts_with_ta_and_villages[district.name][ta_name] = [] if districts_with_ta_and_villages[district.name][ta_name].blank?
  districts_with_ta_and_villages[district.name][ta_name] << village_name
end

ta_location_tag = LocationTag.find_by_name('Traditional Authority')
village_location_tag = LocationTag.find_by_name('Village')
(districts_with_ta_and_villages || {}).each_with_index do |(district_name, ta_and_villages), i|
  district = Location.find_by_name(district_name)
  (ta_and_villages || {}).each do |ta, villages|
    traditional_authority = Location.create(name: ta, description: 'Traditional Authority')
    LocationTagMap.create(location_id: traditional_authority.id, location_tag_id: ta_location_tag.id)
    traditional_authority.update_attributes(parent_location: district.id)

    (villages || []).each_with_index do |village_name, i|
      village = Location.create(name: village_name, description: 'A village under a TA')
      LocationTagMap.create(location_id: village.id, location_tag_id: village_location_tag.id)
      village.update_attributes(parent_location: traditional_authority.id)
      puts "#{village_name} #####{villages.length - i} to go for district: #{district_name}"
    end
  end
end

location_tag = LocationTag.find_by_name('Facility location')
['Help desk','Call booth'].each do |name|
  location = Location.create(name: name, description: 'Facility location')
  LocationTagMap.create(location_id: location.id, location_tag_id: location_tag.id)
end
###################################### Creating locations ends ################################################################




###################################### Creating Global properties ##############################################################
global_properties = [
  ['call.modes','New,Repeat','Call Type whether New or Repeat'],
  ['current.health.center.name',649,'Sets the current health center using the health center name for Ror.']
]

(global_properties || []).each do |property, property_value, description|
  GlobalProperty.create(property: property, property_value: property_value, description: description)
end
###################################### Creating Global properties ends ##############################################################






puts "Your new user is: admin, password: adminhotline"
