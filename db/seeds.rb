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
  UserRole.create(:user_id => user.id, :role => role)
end

puts "Your new user is: admin, password: Admin123"
