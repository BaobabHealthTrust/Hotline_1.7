def fix_null_comments
	puts '###-------------------------------------------------###'
	puts '#                                                     #'
	puts '# Fixing null comments to a valid corresponding value #'
	puts '#                                                     #'
	puts '###-------------------------------------------------###'
	
	# Get person ids for records with null comments field
	obs_person_ids_with_null_comments = ActiveRecord::Base.connection.execute('
											SELECT person_id FROM obs WHERE comments IS NULL
										')
	obs_person_ids_without_null_comments = ActiveRecord::Base.connection.execute('
											SELECT person_id FROM obs WHERE comments IS NOT NULL
										')
	
	null_comments_person_ids = []
	no_null_comments_person_id = []
	
	# put person id with null comments into an array
	obs_person_ids_with_null_comments.each do |person_id|
		puts "#{person_id}"
		null_comments_person_ids << person_id
	end
	
	# put person id without null comments into an array
	obs_person_ids_without_null_comments.each do |person_id|
		puts "#{person_id}"
		no_null_comments_person_id << person_id
	end
	
	puts "null comments ids = #{null_comments_person_ids}"
	puts "no null comments id = #{no_null_comments_person_id}"
	
	# increament null value with 1 based on condition of existence
	null_comments_person_ids.each do |null_pid|
		if no_null_comments_person_id.include? null_pid
			# get the max value of the comments field under that person_id and increment with 1
			pids_max_comment = ActiveRecord::Base.connection.execute("
				
			                                                         ")
			puts "#{null_pid.first} in null array"
		else
			# set null value to 1
			ActiveRecord::Base.connection.execute("
				UPDATE obs set comments = '1'
				WHERE person_id = #{null_pid.first}
			                                      ")
			puts"#{null_pid.first} not in no_null array"
		end
	end
	
	puts "#{null_comments_person_ids}"
	puts "#{obs_person_ids_with_null_comments.count}"
end

fix_null_comments