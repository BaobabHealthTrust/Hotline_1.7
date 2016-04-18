class PatientController < ApplicationController
  def dashboard
    
    @tab_name = params[:tab_name] 
    @tab_name = 'current_call' if @tab_name.blank?
    @patient_obj = PatientService.get_patient(params[:patient_id])

    @current_encounters = Encounter.where(patient_id: params[:patient_id], 
      encounter_datetime: (Date.today.strftime('%Y-%m-%d 00:00:00')) .. (Date.today.strftime('%Y-%m-%d 23:59:59')))
    @current_encounter_names = @current_encounters.collect{|e| e.type.name.upcase}
    @previous_encounters = Encounter.where("patient_id = ? AND encounter_datetime < ?",
      params[:patient_id], Date.today.strftime('%Y-%m-%d 00:00:00'))

    #Adding tasks in proper order
    @tasks = []
    if @patient_obj.sex.match('F') && @patient_obj.age > 13 && @patient_obj.age < 50  
      @tasks << {"name" => "Pregnancy Status",
                 "link" => "/encounters/new/pregnancy_status?patient_id=#{@patient_obj.patient_id}",
                 'icon' => "pregnacy.png",
                 'done' => @current_encounter_names.include?('PREGNANCY STATUS')}
    end

    if @patient_obj.sex.match('F') || @patient_obj.age <= 5
      @tasks << {"name" => "Symptoms",
                 "link" =>"/encounters/new/female_symptoms?patient_id=#{@patient_obj.patient_id}",
                 'icon' => "symptoms-2.png",
                 'done' => @current_encounter_names.include?('MATERNAL HEALTH SYMPTOMS')}
    end

    @tasks << {"name" => "Outcomes", "link" => "/encounters/new/update_outcomes?patient_id=#{@patient_obj.patient_id}",
               'icon' => "symptoms.png",
               'done' => @current_encounter_names.include?('UPDATE OUTCOME')}
    if @patient_obj.sex.match('F')
      @tasks << {"name" => "Clinic Schedule",
                 "link" => "/encounters/new/schedule?patient_id=#{@patient_obj.patient_id}",
                 "icon" => "calendar-and-tasks.png",
                 'done' => @current_encounter_names.include?('APPOINTMENT')}
    end

    if @patient_obj.sex.match('F')
      @tasks << {"name" => "Edit reminders",
                 "link" => "/encounters/new/reminders?patient_id=#{@patient_obj.patient_id}",
                 "icon" => "notification.png",
                 'done' => @current_encounter_names.include?('TIPS AND REMINDERS')}
    end

    @tasks << {"name" => "Purpose of Call",
               "link" => "/encounters/new/purpose_of_call?patient_id=#{@patient_obj.patient_id}",
               "icon" => "call_purpose.png",
               'done' => @current_encounter_names.include?('PURPOSE OF CALL')}

    @tasks << {"name" => "Nutrition",
               "link" => "/encounters/new/clinical_assessment?patient_id=#{@patient_obj.patient_id}",
               "icon" => "nutrition_module.png",
               'done' => @current_encounter_names.include?('DIETARY ASSESSMENT') || @current_encounter_names.include?('CLINICAL ASSESSMENT')}

    @tasks << {"name" => "Edit demographics",
               "link" => "/demographics/#{@patient_obj.patient_id}",
               "icon" => "demographic.png"}

    @tasks << {"name" => "Reference material",
               "link" => "/patient/reference_material/#{@patient_obj.patient_id}",
               "icon" => "reference.png"}

    @tasks << {"name" => "Next Client",
               "link" => "/patient/districts?param=verify_purpose&patient_id=#{@patient_obj.patient_id}&next_client=true",
               "icon" => "next.png"}

    @tasks << {"name" => "Nutrition Summary",
               "link" => "/encounters/nutrition_summary?patient_id=#{@patient_obj.patient_id}",
               "icon" => "nutrition_summary.png",
               'done' => @current_encounter_names.include?('DIETARY ASSESSMENT') || @current_encounter_names.include?('CLINICAL ASSESSMENT')}

    @tasks << {"name" => "End Call",
               'link' => "/patient/districts?param=verify_purpose&patient_id=#{@patient_obj.patient_id}&end_call=true",
               'icon' => 'end-call.png'}

    symptom_encounter_type = EncounterType.find_by_name('Maternal health symptoms')
    @symptom_encounters = Encounter.where('patient_id = ? AND encounter_type = ?',
      params[:patient_id], symptom_encounter_type.id).group(:encounter_datetime)
    render :layout => false
  end

  def reference_material
    @material = Publify.find_by_sql("SELECT * FROM contents c WHERE c.type = 'Article'")
    render :layout => false
  end

  def reference_article
    @article = Publify.find_by_sql("SELECT * FROM contents c WHERE c.type = 'Article' AND id = #{params[:article_id]}").first
    render :layout => false
  end

  def search_result
    @given_name = params[:person]['names']['given_name']
    @family_name = params[:person]['names']['family_name']
    @gender = params[:person]['gender']
    unless params[:action_type] == 'new_client'
      params[:person]['names']['given_name'] = @given_name
      params[:person]['names']['family_name'] = @family_name
      @gender = params[:person]['gender']
    end

    flash[:missing_family_name] = "Family Name can not be blank, please include patient family name."
    @people = PatientService.find_by_demographics(params)
    render :layout => false
  end

  def new
    flash[:age_max_digits] = 'Incorrect Input! Age should have a maximum of 3 digits.'
    flash[:age_out_of_range] = 'Incorrect Input! Age should be between 0 and 150.'
    flash[:age_blank] = 'Incorrect Input! Age can not be blank.'
    @given_name = params['given_name']
    @family_name = params['family_name']
    @gender = params['gender']
    render :layout => false
  end

  def new_with_demo
    @patient_obj = PatientService.get_patient(params[:patient_id])
  end

  def create

    patient_obj = PatientService.create(params)
    if params[:action_type] && params[:action_type] == 'guardian'
      redirect_to "/encounters/new/reminders?patient_id=#{params[:patient_id]}&guardian_id=#{patient_obj.patient_id}" and return
    end
    redirect_to "/patient/new_with_demo/#{patient_obj.patient_id}"
  end

  def add_patient_attributes
    patient_obj = PatientService.get_patient(params[:patient_id])
    PatientService.add_patient_attributes(patient_obj, params)

    #location = LocationTag.find_by_name(params[:person][:current_region]).location_tag_id

    PersonAddress.create(
        person_id: patient_obj.patient_id,
        address2: params[:person][:addresses][:home_district],
        county_district: params[:person][:addresses][:home_ta],
        neighborhood_cell: params[:person][:addresses][:home_village],
        region: params[:person][:addresses][:region_of_origin]
    )
    redirect_to "/encounters/new/purpose_of_call?patient_id=#{patient_obj.patient_id}"
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
    people = []

    @attribute_name = params[:attribute_name].titleize
    @attribute = params[:attribute_value]

    case @attribute_name
      when 'Phone Number'
        types = [-1] + PersonAttributeType.where("name IN ('Cell Phone Number', 'Office Phone Number', 'Home Phone Number')").map(&:person_attribute_type_id)
        patient_ids = PersonAttribute.where(["person_attribute_type_id IN (?) AND value LIKE '%#{@attribute.to_i}%' ", types]).select('person_id').collect{|o| o.person_id}

        concept_ids = ["Telephone Number"].collect{|num| ConceptName.find_by_name(num).concept_id rescue -1}
        patient_ids << Observation.where(["concept_id = ? AND value_numeric LIKE '%#{@attribute.to_i}%'", concept_ids, ]).select('person_id').collect{|o| o.person_id}

        people = Person.where(['person_id > 1 AND person_id IN (?)', patient_ids.flatten])
      when 'Identifier'
        types = ['IVR access code', 'National id'].collect{|type| PatientIdentifierType.find_by_name(type).id rescue -1}
        patient_ids = PatientIdentifier.where(["identifier_type IN (?) AND identifier LIKE '%#{@attribute}%'", types]).select('patient_id').collect{|o| o.patient_id}
        people = Person.where(['person_id > 1 AND person_id IN (?)', patient_ids.flatten])
    end

    @people = []
    people.each do |person|
      @people << PatientService.get_patient(person.id)
    end

    render :layout => false
  end

  def regions
    #location_tag = LocationTag.find_by_name("Region")
    location_tag = LocationTag.find_by_description("Regions of Malawi")
    @regions = Location.where("m.location_tag_id = #{location_tag.id}").joins("INNER JOIN location_tag_map m
     ON m.location_id = location.location_id").collect{|l | [l.id, l.name]}
    @region_names = @regions.collect { |region_id, region_name| region_name}

    return @region_names
  end

  def district
    unless params[:filter_value].blank?
      region_id = LocationTag.find_by_name('Northern').id if params[:filter_value].match(/North/i)
      region_id = LocationTag.find_by_name('Central').id if params[:filter_value].match(/Centr/i)
      region_id = LocationTag.find_by_name('South').id if params[:filter_value].match(/Sout/i)
    else
      region_id = 0
    end
    
    location_tag = LocationTag.find_by_name('District')
    @districts = Location.where("region = ? AND name LIKE(?)",region_id,"%#{params[:search_string]}%")
    Location.where("parent_location IN(?) AND t.location_tag_id = ?", 
      @districts.map(&:id), location_tag.id).joins("INNER JOIN location_tag_map t USING(location_id)").map do |l|
      @districts << l
    end
    data = @districts.collect { |l | l.name }
    
    unless data.blank?
      render text: "<li>" + data.sort.map{|n| n } .join("</li><li>") + "</li>" and return
    else
      #render text: [].to_json and return
      render text: "<li></li>" and return
    end
  end

  def ta
    location_tag = LocationTag.find_by_name('Traditional Authority')
    district = Location.where(name: params[:filter_value]).first

    @ta = Location.where("parent_location = ? AND m.location_tag_id = ? 
      AND name LIKE(?)",district.id, location_tag.id, "%#{params[:search_string]}%").joins("INNER JOIN location_tag_map m USING(location_id)")
    data = @ta.collect { |l | l.name }

    unless data.blank?
      render text: "<li>" + data.sort.map{|n| n } .join("</li><li>") + "</li>" and return
    else
      #render text: [].to_json and return
      render text: "<li></li>" and return
    end
  end

  def village
    district = Location.find_by_name(params[:district])
    ta = Location.where(name: params[:filter_value], parent_location: district.id).first
    location_tag = LocationTag.find_by_name("Village")

    @villages = Location.where("parent_location = ? AND m.location_tag_id = ? 
      AND name LIKE(?)",ta.id, location_tag.id, "%#{params[:search_string]}%").joins("INNER JOIN location_tag_map m USING(location_id)")
    data = @villages.collect { |l | l.name }

    unless data.blank?
      render text: "<li>" + data.sort.map{|n| n } .join("</li><li>") + "</li>" and return
    else
      #render text: [].to_json and return
      render text: "<li></li>" and return
    end
  end

  def districts
    if params[:param] == 'verify_purpose'
      ###
      #
      # Below code to be modified into an array to avoid repeating code.
      ##############################################################################
      checks = ['encounter_id' => ['purpose_encounter_id',
                                  'outcome_encounter_id'],
                'encounter_type_name' => ['Purpose of call',
                                  'Update outcome']]

      purpose_encounter_id = EncounterType.find_by_name('Purpose of call').encounter_type_id

      outcome_encounter_id = EncounterType.find_by_name('Update outcome').encounter_type_id

      symptoms_encounter_id = EncounterType.find_by_name('Maternal health symptoms').encounter_type_id

      verify_purpose_encounter = Encounter.where(patient_id: params[:patient_id], :encounter_type => purpose_encounter_id,
                                            encounter_datetime: (Date.today.strftime('%Y-%m-%d 00:00:00')) ..
                                                (Date.today.strftime('%Y-%m-%d 23:59:59'))).last

      update_outcome_encounter = Encounter.where(patient_id: params[:patient_id], :encounter_type => outcome_encounter_id,
                                                 encounter_datetime: (Date.today.strftime('%Y-%m-%d 00:00:00')) ..
                                                     (Date.today.strftime('%Y-%m-%d 23:59:59'))).last

      symptoms_encounter = Encounter.where(patient_id: params[:patient_id], :encounter_type => symptoms_encounter_id,
                                                 encounter_datetime: (Date.today.strftime('%Y-%m-%d 00:00:00')) ..
                                                     (Date.today.strftime('%Y-%m-%d 23:59:59'))).last

      if verify_purpose_encounter.nil? || verify_purpose_encounter.observations.last.nil?
        redirect_to "/encounters/new/confirm_purpose_of_call?patient_id=#{params[:patient_id]}" and return
      elsif update_outcome_encounter.nil? || update_outcome_encounter.observations.last.nil?
        if params[:end_call] == 'true'
          redirect_to "/encounters/new/update_outcomes?patient_id=#{params[:patient_id]}&end_call=#{params[:end_call]}" and return
        elsif params[:next_client] == 'true'
          redirect_to "/encounters/new/update_outcomes?patient_id=#{params[:patient_id]}" and return
        end
      elsif params[:end_call] == 'true'
          redirect_to '/' and return
      end
    end

    location_tag = LocationTag.find_by_name("District")
    @districts = Location.where("m.location_tag_id = #{location_tag.id}").joins('INNER JOIN location_tag_map m
     ON m.location_id = location.location_id').collect{|l | [l.id, l.name]}

    @location_names = @districts.collect { |location_id, location_name| location_name}
    @call_modes = [''] + GlobalProperty.find_by(:description => 'call.modes').property_value.split(',')
  end

  def observations
    observations = []
    (Encounter.find(params[:encounter_id]).observations || []).each do |ob|
      value = ConceptName.where(concept_id: ob.value_coded).first.name rescue nil
      if value.blank?
        value = ob.value_datetime.to_time.strftime('%d/%b/%Y') rescue nil
      end

      if value.blank?
        value = ob.value_numeric rescue nil
      end

      if value.blank?
        value = ob.value_text rescue nil
      end

      observations << [ob.concept.concept_names.first.name, value]
    end

    render text: observations.to_json and return
  end

  def number_of_booked_patients
    date = params[:date].to_date
    encounter_type = EncounterType.find_by_name('APPOINTMENT')
    concept_id = ConceptName.find_by_name('Next anc visit date').concept_id

    start_date = date.strftime('%Y-%m-%d 00:00:00')
    end_date = date.strftime('%Y-%m-%d 23:59:59')

    appointments = Observation.find_by_sql("SELECT count(DISTINCT(obs.person_id)) AS count FROM obs
      INNER JOIN encounter e USING(encounter_id) WHERE concept_id = #{concept_id}
      AND encounter_type = #{encounter_type.id} AND value_datetime >= '#{start_date}'
      AND value_datetime <= '#{end_date}' AND obs.voided = 0 GROUP BY value_datetime")
    count = appointments.first.count unless appointments.blank?
    count = '0' if count.blank?

    render :text => (count.to_i >= 0 ? {params[:date] => count}.to_json : 0)
  end

  def void_encounter
    e = Encounter.find(params[:encounter_id])
    (e.observations || []).each do |ob|
      ob.update_attributes(voided: true, void_reason: 'N/A')
    end
    patient_id = e.patient_id
    e.update_attributes(voided: true, void_reason: 'N/A')
    redirect_to "/patient/dashboard/#{patient_id}/#{params[:tab_name]}"
  end

  def test
    @patient_obj = Patient.find(params['patient_id'])
  end

  def dietary_assessment
    @patient_obj = Patient.find(params['patient_id'])
  end
  private

  def search(field_name, search_string, gender = nil)
    case field_name
      when 'given_name'
        @names = PersonName.where("c.given_name_code LIKE(?)", "%#{search_string.soundex}%").joins("INNER JOIN person_name_code c 
          ON c.person_name_id = person_name.person_name_id").group(:given_name).limit(30).collect do |rec| 
            rec.given_name
        end
      when 'family_name'
        @names = PersonName.where("c.family_name_code LIKE(?)", "%#{search_string.soundex}%").joins("INNER JOIN person_name_code c 
          ON c.person_name_id = person_name.person_name_id").group(:family_name).limit(30).collect do |rec| 
            rec.family_name
        end
      when 'given_name_plus_family_name'
        given_name_code = search_string.squish.split(' ')[0].soundex rescue ''
        family_name_code = search_string.squish.split(' ')[1].soundex rescue ''
        family_name_code = given_name_code if family_name_code.blank?

        @names = PersonName.where("(c.given_name_code LIKE(?) OR c.family_name_code LIKE(?)) AND p.gender=?", 
          "%#{given_name_code}%","%#{family_name_code}%",gender.first).joins("INNER JOIN person_name_code c 
          ON c.person_name_id = person_name.person_name_id INNER JOIN person p 
          ON p.person_id = person_name.person_id").group(:family_name).limit(30).collect do |rec| 
            [rec.given_name, rec.family_name]
        end
        render :text => "<li>" + @names.map{|f,l| "#{f} #{l}" } .join("</li><li>") + "</li>" and return
    end
    render :text => "<li>" + @names.map{|n| n } .join("</li><li>") + "</li>"
  end

end
