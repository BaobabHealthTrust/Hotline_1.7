def fix_null_comments
	puts '###-------------------------------------------------###'
	puts '#                                                     #'
	puts '# Fixing null comments to a valid corresponding value #'
	puts '#                                                     #'
	puts '###-------------------------------------------------###'
	
	# Get person ids for records with null comments field
	obs_person_ids_with_null_comments = ActiveRecord::Base.connection.execute('SELECT person_id FROM obs WHERE comments IS NULL')
	
	null_comments_person_ids = []
	
	# put person id into an array
	obs_person_ids_with_null_comments.each do |person_id|
		puts "#{person_id}"
		null_comments_person_ids << person_id
	end
	
	# update every null comment with an increment value based on the max value
	null_comments_person_ids.each do |null_pids|
		puts "#{null_pids}"
	end
	
	puts "#{null_comments_person_ids}"
	puts "#{obs_person_ids_with_null_comments.count}"
end

fix_null_comments