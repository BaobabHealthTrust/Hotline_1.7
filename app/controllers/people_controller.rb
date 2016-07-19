class PeopleController < ApplicationController

	def guardian_check
		@patient_obj = PatientService.get_patient(params[:patient_id])
		@patient = Patient.find(params[:patient_id])
		if request.post?
			if params[:guardian_available] == 'Yes'
				redirect_to "/patient/search_by_name?action_type=guardian&patient_id=#{@patient_obj.patient_id}" and return
			end
			session[:no_guardian] = true
			redirect_to next_task(@patient_obj)
		end
	end

	def demographics
		@patient_obj = PatientService.get_patient(params[:patient_id])
		@person_name = get_patient_names(params[:patient_id])
		@infant_age = PatientService.get_infant_age(@patient_obj) if @patient_obj.age < 1
		@phoneType = Observation.where(
			  :concept_id => ConceptName.where(:name => "Phone Type").last.concept_id,
			  :person_id => params[:patient_id]
		).last.answer_string rescue nil
		render :layout => false
	end

	def get_patient_names(patient_id)
		patient_names = PersonName.where(person_id: patient_id).first
		return patient_names
	end

	def get_patient_addresses(patient_id)
		patient_addresses = PersonAddress.where(person_id: patient_id).first
		if patient_addresses.nil?
			patient_addresses = PersonAddress.create(person_id: patient_id)
		end
		return patient_addresses
	end

	def get_patient_attributes(patient_id)
		patient_attributes = PersonAttribute.where(person_id: patient_id).first
		if patient_attributes.nil?
			patient_attributes = PersonAttribute.create(person_id: patient_id)
		end
		return patient_attributes
	end

	def update_patient_names(names)
		names.save
	end

	def update_patient(patient)
		patient.save
	end

	def update_attributes(patient_attributes)
		patient_attributes.save
	end

	def update_addresses(patient_addresses)
		patient_addresses.save
	end

	def demographic_modify
		if request.post?
			#------ get records for patient -----
			patient = Person.find(params[:patient_id])
			patient_names = get_patient_names(patient.person_id)
			patient_addresses = get_patient_addresses(patient.person_id)
			patient_attributes = get_patient_attributes(patient.person_id)

			case params[:field]
				#------ set names -------------------------
				when 'name'
					patient_names.given_name = params[:given_name]
					patient_names.family_name = params[:family_name]

				#------ set person (gender) -----------------
				when 'sex'
					patient.gender = params[:gender] unless params[:gender].blank?

				#------ set person(birthdate) ----------------
				when 'age'
					birthdate = PatientService.format_birthdate_params(params[:person])
					patient.birthdate = birthdate[0].to_date

				#------- set addresses ---------------------
				when 'location'
					params[:addresses] = params[:person][:addresses]
					patient_addresses.region = params[:addresses][:region_of_origin]
					patient_addresses.address2 = params[:addresses][:home_district]
					patient_addresses.county_district = params[:addresses][:home_ta]
					patient_addresses.neighborhood_cell = params[:addresses][:home_village]

				#------- set attributes --------------------
				when 'phone_numbers'
					patient_attributes = PersonAttribute.where(:person_id => patient.person_id,
					                                           :person_attribute_type_id => PersonAttributeType.find_by_name("Cell Phone Number").id).first_or_create

					patient_attributes.value = params[:person][:phone_numbers]

					params['observations'].each do |observation|
						ob = Observation.where(
							  :concept_id => ConceptName.where(
									:name => observation['concept_name']
							  ).last.concept_id,
							  :person_id => params[:patient_id]
						).last rescue nil
						next if ob.blank?
						ob.value_text = observation['value_text']
						ob.save
					end

				when 'district_of_residence'
					patient_attributes = PersonAttribute.where(:person_id => patient.person_id,
					                                           :person_attribute_type_id => PersonAttributeType.find_by_name("Nearest Health Facility").id).first_or_create
					patient_attributes.value =  params['nearest_health_facility']
					patient_attributes.save

					patient_addresses.township_division = params['district']
					patient_addresses.save
=begin
          health_facility = Observation.where(
              :person_id => params[:patient_id],
              :concept_id => ConceptName.where(:name => "Nearest Health Facility").last.concept_id,
          ).last

          health_facility.value_text = params['nearest_health_facility']
          health_facility.save
=end
				when 'mothers_name'
					patient_names.family_name2 = params['person']['names']['family_name2']
			end

			#------ save modified records --------
			update_patient(patient) if params[:field] == 'sex' || params[:field] == 'age'
			update_patient_names(patient_names) if params[:field] == 'name' || params[:field] == 'mothers_name'
			update_addresses(patient_addresses) if params[:field] == 'location'
			update_attributes(patient_attributes) if params[:field] == 'phone_numbers'

			redirect_to "/patient/dashboard/#{patient.person_id}/tasks?next_task=#{params[:next_task]}" and return if !params[:next_task].blank?
			redirect_to "/demographics/#{patient.person_id}"
		else
			@edit_page      = params[:field]
			@patient_obj    = PatientService.get_patient(params[:patient_id])
			@patient_name   = PersonName.where(:person_id => params[:patient_id]).last
			birthdate       = @patient_obj.birthdate.split('/')

			@birthday       = (birthdate[0]=='??')?'Unknown':birthdate[0]
			@birthmonth     = (birthdate[1]=='???')?'Unknown':birthdate[1]
			@birthyear      = birthdate[2]

			location_tag = LocationTag.find_by_name("District")
			@districts = Location.where("m.location_tag_id = #{location_tag.id}").joins('INNER JOIN location_tag_map m
     ON m.location_id = location.location_id').collect{|l | [l.id, l.name]}

			@location_names = @districts.collect { |location_id, location_name| location_name}
		end
	end

	def new_hsa
		@person = Person.new
	end

	def search_hsa
		unless request.get?
			#raise params.inspect
			family_name = params[:person]['names']['family_name']
			given_name = params[:person]['names']['given_name']
			gender = params[:person][:gender]
			@person = PersonName.where(family_name: family_name, given_name: given_name).first
			redirect_to "/people/edit_hsa/#{@person.id}"
		end
	end


	def select_hsa
		render :layout => true
	end

	def edit_hsa
		@person = Person.find(params[:person_id])
	end


	def update_hsa
		person = Person.find(params[:person_id])
		person.update_attribute(:gender, params[:person]['gender'].first)
		person_name = PersonName.where(person_id: person.person_id).first
		person_name.update_attributes(:given_name => params[:person]['names']['given_name'],
		                              :family_name => params[:person]['names']['family_name'] )

		birthdate = PatientService.format_birthdate_params(params[:person])
		person.update_attributes(birthdate: birthdate[0].to_date, birthdate_estimated: birthdate[1])

		if params[:person]['cell_phone_number']
			attribute_type = PersonAttributeType.find_by_name('Cell phone number')
			person_attribute = PersonAttribute.where(person_id: person.id,
			                                         person_attribute_type_id: attribute_type.id)

			if person_attribute.blank?
				PersonAttribute.create(value: params[:person]['cell_phone_number'],
				                       person_id: person.id, person_attribute_type_id: attribute_type.id)
			else
				person_attribute.first.update_attributes(value: params[:person]['cell_phone_number'])
			end
		end

		redirect_to '/manage_user'
	end


	def create_hsa

		birthdate = PatientService.format_birthdate_params(params[:person])
		person = Person.create(birthdate: birthdate[0].to_date, birthdate_estimated: birthdate[1],
		                       gender: params[:person]['gender'].first)

		person_attribute = PersonAttribute.create(person_id: person.id,
		                                          value: params[:person]['cell_phone_number'],
		                                          person_attribute_type_id: PersonAttributeType.where("name = 'Health Surveillance Assistant'").first.person_attribute_type_id)

		person_name = PersonName.create(given_name: params[:person]['names']['given_name'],
		                                family_name: params[:person]['names']['family_name'], person_id: person.id)

		PersonNameCode.create(given_name_code: person_name.given_name.soundex,
		                      family_name_code: person_name.family_name.soundex, person_name_id: person_name.id)

		# unless params[:person]['cell_phone_number'].blank?
		#   person_attribute_type = PersonAttributeType.find_by_name('Health Surveillance Assistant')
		#   PersonAttribute.create(value: params[:person]['cell_phone_number'],
		#     person_id: person.id, person_attribute_type_id: person_attribute_type.id)
		# end

		redirect_to '/manage_user'

	end

	def given_names
		search("given_name", params[:search_string])
	end

	def family_names
		search("family_name", params[:search_string])
	end

	def given_name_plus_family_name
		search("given_name_plus_family_name", params[:search_string],params[:gender])
	end

	def attributes_search_results
		@people = []
		(Person.where('person_id > 1') || []).each do |person|
			@people << PatientService.get_patient(person.id)
		end

		@attribute_name = params[:attribute_name].titleize
		@attribute = params[:attribute_value]
		render :layout => false
	end

	def districts
		location_tag = LocationTag.find_by_name("District")
		@districts = Location.where("m.location_tag_id = #{location_tag.id}").joins("INNER JOIN location_tag_map m
     ON m.location_id = location.location_id").collect{|l | [l.id, l.name]}
		@location_names = @districts.collect { |location_id, location_name| location_name}
		@call_modes = [""] + GlobalProperty.find_by(:description => "call.modes").property_value.split(",")
	end

	def hsa_list
		person_attribute_type = PersonAttributeType.find_by_name('Health surveillance assistant')
		@people = Person.where("a.person_attribute_type_id = ?",
		                       person_attribute_type.id).joins("INNER JOIN person_attribute a USING(person_id)")
		render :layout => false
	end

	def hsa_dashboard
		@person = Person.find(params[:person_id])
	end

	def edit_selected_hsa
		redirect_to "/people/edit_hsa/#{params[:person_id]}"
	end

end
