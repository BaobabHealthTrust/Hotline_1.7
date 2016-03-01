class EncountersController < ApplicationController

  def create
    #raise params.inspect
    if (params[:edit_anc_connect])
      session[:edit_anc_connect] = true
    end

    if session[:house_keeping_mode]
      if params['encounter']['encounter_type_name'].upcase == "BABY DELIVERY"
        session[:report_task] = 'delivery'

      elsif params['encounter']['encounter_type_name'].upcase == "BIRTH PLAN"
        session[:report_task] = 'birth_plan'

      elsif params['encounter']['encounter_type_name'].upcase == "ANC VISIT"
        session[:report_task] = 'anc_visit'
      end
    end

    Encounter.find(params[:encounter_id].to_i).void("Editing Tips and Reminders") if(params[:editing] && params[:encounter_id])
    if params['encounter']['encounter_type_name'] == 'ART_INITIAL'
      if params[:observations][0]['concept_name'] == 'EVER RECEIVED ART' and params[:observations][0]['value_coded_or_text'] == 'NO'
        observations = []
        (params[:observations] || []).each do |observation|
          next if observation['concept_name'] == 'HAS TRANSFER LETTER'
          next if observation['concept_name'] == 'HAS THE PATIENT TAKEN ART IN THE LAST TWO WEEKS'
          next if observation['concept_name'] == 'HAS THE PATIENT TAKEN ART IN THE LAST TWO MONTHS'
          next if observation['concept_name'] == 'ART NUMBER AT PREVIOUS LOCATION'
          next if observation['concept_name'] == 'DATE ART LAST TAKEN'
          next if observation['concept_name'] == 'LAST ART DRUGS TAKEN'
          observations << observation
        end
      elsif params[:observations][4]['concept_name'] == 'DATE ART LAST TAKEN' and params[:observations][4]['value_datetime'] != 'Unknown'
        observations = []
        (params[:observations] || []).each do |observation|
          next if observation['concept_name'] == 'HAS THE PATIENT TAKEN ART IN THE LAST TWO WEEKS'
          next if observation['concept_name'] == 'HAS THE PATIENT TAKEN ART IN THE LAST TWO MONTHS'
          observations << observation
        end
      end
      params[:observations] = observations unless observations.blank?
    end

    @patient = Patient.find(params[:encounter][:patient_id])
    #>>>>>>>>>>>>>WE DON'T WANT DUPLICATE ENCOUNTERS AND OBSERVATIONS ON THE SAME DAY>>>>>>>>>>
    my_enc_name =  params['encounter']['encounter_type_name'] rescue nil
    my_enc_type_id = EncounterType.find_by_name(my_enc_name).id rescue nil
    my_enc = Encounter.find(:last, :conditions => ["patient_id =? AND encounter_type =? AND
        DATE(encounter_datetime) =?", @patient.id, my_enc_type_id, Date.today]) rescue nil
    my_enc.void("REMOVING DUPLICATE ENCOUNTERS") unless my_enc.blank?
    #>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>
    # Go to the dashboard if this is a non-encounter
    redirect_to "/patients/show/#{@patient.id}" unless params[:encounter]

    encounter               = nil
    this_encounter          = params[:encounter][:encounter_type_name]
    exceptional_encounters  = ["REGISTRATION"]
=begin
	current_observations = nil;
    # added this to append the call id observation the list of observaations
	if params[:observations] != nil
    	current_observations = params[:observations]
	else
		current_observations = []
	end

   	new_observation = {"patient_id"=> "#{@patient.id}", "concept_name" => "CALL ID", "obs_datetime" => "#{DateTime.now()}", "value_coded_or_text" => "#{session[:call_id]}"}
    current_observations << new_observation

    params[:observations] = current_observations
=end
    # Handling exceptional encounters i.e. that do not necessarily need observations such as Registration

    encounter = Encounter.create(params[:encounter], session[:datetime]) if (exceptional_encounters.include? this_encounter)
=begin
    # Observation handling
    (params[:observations] || []).each do |observation|

      # Check to see if any values are part of this observation
      # This keeps us from saving empty observations
      values = ['coded_or_text', 'coded_or_text_multiple', 'group_id', 'boolean', 'coded', 'drug', 'datetime', 'numeric', 'modifier', 'text'].map{|value_name|
        observation["value_#{value_name}"] unless observation["value_#{value_name}"].blank? rescue nil
      }.compact

      next if values.length == 0

      # Create an encounter if the obsevations are not empty
      # This keeps us from saving empty encounters
      encounter.nil? ? (encounter = Encounter.create(params[:encounter], session[:datetime])) : (encounter = Encounter.find(encounter.id))

      observation[:value_text] = observation[:value_text].join(", ") if observation[:value_text].present? && observation[:value_text].is_a?(Array)
      observation.delete(:value_text) unless observation[:value_coded_or_text].blank?
      observation[:encounter_id] = encounter.id
      observation[:obs_datetime] = encounter.encounter_datetime || Time.now()
      observation[:person_id] ||= encounter.patient_id
      observation[:concept_name] ||= "DIAGNOSIS" if encounter.type.name == "DIAGNOSIS"
      # Handle multiple select
      if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(Array)
        observation[:value_coded_or_text_multiple].compact!
        observation[:value_coded_or_text_multiple].reject!{|value| value.blank?}
      end  
      if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(Array) && !observation[:value_coded_or_text_multiple].blank?
        values = observation.delete(:value_coded_or_text_multiple)
        values.each{|value| observation[:value_coded_or_text] = value; Observation.create(observation) }
      else      
        observation.delete(:value_coded_or_text_multiple)
        Observation.create(observation)
      end
    end
=end
    #Create the observations

    encounter = create_obs(encounter, params)

    if params['encounter']['encounter_type_name'] == "MATERNAL HEALTH SYMPTOMS" && encounter.blank?
      params[:observations].first[:value_coded_or_text] = "None"
      params[:observations].first[:concept_name] = "Current complaints or symptoms"
      encounter = create_obs(encounter, params)
    end
    # Program handling
    date_enrolled = params[:programs][0]['date_enrolled'].to_time rescue nil
    date_enrolled = session[:datetime] || Time.now() if date_enrolled.blank?
    (params[:programs] || []).each do |program|
      # Look up the program if the program id is set      
      @patient_program = PatientProgram.find(program[:patient_program_id]) unless program[:patient_program_id].blank?
      # If it wasn't set, we need to create it
      unless (@patient_program)
        @patient_program = @patient.patient_programs.create(
            :program_id => program[:program_id],
            :date_enrolled => date_enrolled)
      end
      # Lots of states bub
      unless program[:states].blank?
        #adding program_state start date
        program[:states][0]['start_date'] = date_enrolled
      end
      (program[:states] || []).each {|state| @patient_program.transition(state) }
    end

    # Identifier handling
    arv_number_identifier_type = PatientIdentifierType.find_by_name('ARV Number').id
    (params[:identifiers] || []).each do |identifier|
      # Look up the identifier if the patient_identfier_id is set      
      @patient_identifier = PatientIdentifier.find(identifier[:patient_identifier_id]) unless identifier[:patient_identifier_id].blank?
      # Create or update
      type = identifier[:identifier_type].to_i rescue nil
      unless (arv_number_identifier_type != type) and @patient_identifier
        arv_number = identifier[:identifier].strip
        if arv_number.match(/(.*)[A-Z]/i).blank?
          identifier[:identifier] = "#{Location.current_arv_code} #{arv_number}"
        end
      end

      if @patient_identifier
        @patient_identifier.update_attributes(identifier)
      else
        @patient_identifier = @patient.patient_identifiers.create(identifier)
      end
    end

    session[:mnch_protocol_required]  = true if (encounter && (encounter.name == "PREGNANCY STATUS" || encounter.name == "CHILD HEALTH SYMPTOMS"))
    if (encounter && encounter.name == "UPDATE OUTCOME" && params["select_outcome"] == "REFERRED TO A HEALTH CENTRE")
      session[:outcome_complete]  = true
      session[:health_facility]   = params["health_center"]
    end


    if session[:birth_plan_update] || session[:anc_visit_update] || session[:anc_visit_update]
      redirect_to next_task(@patient) and return
    end

    if params['encounter']['encounter_type_name'] == 'BABY DELIVERY'
      if params[:observations][0]['concept_name'] == 'DELIVERED'
        unless params[:observations][0]['value_coded'].blank?
          yes_concept = ConceptName.find_by_concept_id(params[:observations][0]['value_coded']).name.upcase
          if yes_concept == 'YES'
            if params[:late_anc_call].present? && params[:late_anc_call].to_s == "true"
              de_enroll_and_deliver(params[:observations][0]['patient_id'])
              redirect_to "/clinic/district?task=delivery&district=#{session[:district]}" and return
            else
              redirect_to next_task(@patient) and return
            end
          else
            if session[:hsa_response].blank?  && session[:house_keeping_mode]
              session[:hsa_response] = "done"
              redirect_to "/encounters/hsa_response?patient_id=#{params[:observations].first[:patient_id]}&hsa_id=#{params[:hsa_id]}" + "&late=true"  and return
            else
              session.delete(:hsa_response)
              if session[:report_task].to_s.upcase == "anc_visit".upcase
                task_report = "anc"
              else
                task_report = session[:report_task].to_s
              end

              if session[:house_keeping_mode]
                redirect_to "/clinic/district?task=#{task_report}&district=#{session[:district]}" and return
              else
                redirect_to "/patients/show/#{@patient.id}" and return
              end
            end
          end
        end
      end
    end

    if params['encounter']['encounter_type_name'] == 'HSA VISIT'
      if params[:observations][0]['concept_name'] == 'HSA VISIT'
        unless params[:observations][0]['value_coded'].blank?
          yes_concept = ConceptName.find_by_concept_id(params[:observations][0]['value_coded']).name.upcase
          if yes_concept == 'YES'
            if params[:late_anc_call].present? && params[:late_anc_call].to_s == "true"
              redirect_to "/clinic/district?task=anc&district=#{session[:district]}" and return
            else
              redirect_to :controller => 'patients', :action => 'anc_info', :patient_id => params['encounter']['patient_id'], :visit => 'hsa', :hsa_id => params[:hsa_id] and return
            end
          end
        end
      end
    end

    if params['encounter']['encounter_type_name'] == 'ANC VISIT'
      if params[:observations][0]['concept_name'] == 'ANC VISIT'
        unless params[:observations][0]['value_coded'].blank?
          yes_concept = ConceptName.find_by_concept_id(params[:observations][0]['value_coded']).name.upcase
          if yes_concept == 'YES'
            if params[:late_anc_call].present? && params[:late_anc_call].to_s == "true"
              redirect_to :controller => 'clinic', :action => 'district',:task => 'anc', :district => session[:district]  and return
            else
              redirect_to next_task(@patient) and return
            end
          else
            if params['hsa_id'].present?
              if session[:hsa_response].blank?  && session[:house_keeping_mode]
                session[:hsa_response] = "done"
                redirect_to "/encounters/hsa_response?patient_id=#{params[:observations].first[:patient_id]}&hsa_id=#{params[:hsa_id]}" + "&late=true&fff"  and return
              else
                session.delete(:hsa_response)
                if session[:report_task].to_s.upcase == "anc_visit".upcase
                  task_report = "anc"
                else
                  task_report = session[:report_task].to_s
                end

                if session[:house_keeping_mode]
                  redirect_to "/clinic/district?task=#{task_report}&district=#{session[:district]}" and return
                else
                  redirect_to "/patients/show/#{@patient.id}" and return
                end
              end
            else
              redirect_to "/patients/show/#{@patient.id}" and return
            end
          end
        end
      end
    end
    # Go to the next task in the workflow (or dashboard)
    redirect_to next_task(@patient)
  end

  def new
    @selected_value = []
    @select_options = select_options # to be removed if below begin uncommented
    @patient = Patient.find(params[:patient_id] || session[:patient_id])
=begin
    @child_danger_signs = @patient.child_danger_signs(concept_set('danger sign'))
    @child_symptoms = @patient.child_symptoms(concept_set('health symptom'))
    @select_options = select_options
    @phone_numbers = patient_reminders_phone_number(@patient)
    @personal_phone_number = @patient.person.get_attribute("Cell Phone Number")
    @last_anc_visit_date = Encounter.get_last_anc_visit_date(@patient.id)
    @last_registration_date = Encounter.get_last_registration_date(@patient.id)
    @female_danger_signs = @patient.female_danger_signs(concept_set('danger sign'))
    @female_symptoms = @patient.female_symptoms(concept_set('health symptom'))
    pregnancy_status_details = @patient.pregnancy_status #rescue []
    #raise pregnancy_status_details.to_yaml
    if ! pregnancy_status_details.empty?  && ! pregnancy_status_details.last.nil? && ! pregnancy_status_details.last == 'Unknown'
      if pregnancy_status_details.last.to_date < Date.today && pregnancy_status_details.first.upcase = "PREGNANT"
        @current_pregnancy_status = ""
        @current_pregnancy_status_details = ""
      else
        @current_pregnancy_status = pregnancy_status_details.first rescue nil
        @current_pregnancy_status_details = pregnancy_status_details.last rescue nil
      end
    else
      @current_pregnancy_status = pregnancy_status_details.first rescue nil
      @current_pregnancy_status_details = pregnancy_status_details.last rescue nil
    end
    #raise @child_symptoms.to_s
    if (@child_danger_signs == "Yes" || @female_danger_signs == "Yes")
      @selected_value = ["REFERRED TO A HEALTH CENTRE"]
    elsif (@child_symptoms == "Yes")
      @selected_value = ["REFERRED TO NEAREST VILLAGE CLINIC"]
    elsif (@female_symptoms == "Yes")
      @selected_value = ["GIVEN ADVICE"]
    else
      @selected_value = ["GIVEN ADVICE"]
    end

    # created a hash of 'upcased' health centers
#=begin
    @health_facilities = ([""] + ClinicSchedule.health_facilities.map(&:name)).inject([]) do |facility_list, facilities|
      facility_list.push(facilities)
    end
#=end
    @health_facilities = healthcenter
    #raise @select_options['danger_signs'].to_yaml
    @tips_and_reminders_enrolled_in = type_of_reminder_enrolled_in(@patient)

    use_regimen_short_names = GlobalProperty.find_by_property(
        "use_regimen_short_names").property_value rescue "false"
    show_other_regimen = GlobalProperty.find_by_property(
        "show_other_regimen").property_value rescue 'false'

    @answer_array = arv_regimen_answers(:patient => @patient,
                                        :use_short_names    => use_regimen_short_names == "true",
                                        :show_other_regimen => show_other_regimen      == "true")
    redirect_to "/" and return unless @patient

    @encounter_answers  = {}
    (!params[:encounter_id].blank?) ? (@encounter_id = params[:encounter_id].to_i) : (@encounter_id = nil)
    @encounter_answers  = Encounter.retrieve_previous_encounter(@encounter_id) unless @encounter_id.nil?

    @tips_answer = {}

    if (params[:anc_connect_workflow_start])
      session[:anc_connect_workflow_start] = true
    end

    redirect_to next_task(@patient) and return unless params[:encounter_type]

    redirect_to :action => :create, 'encounter[encounter_type_name]' => params[:encounter_type].upcase, 'encounter[patient_id]' => @patient.id and return if ['registration'].include?(params[:encounter_type])
=end
    render :action => params[:encounter_type] if params[:encounter_type]
  end

  def diagnoses
    search_string = (params[:search_string] || '').upcase
    filter_list = params[:filter_list].split(/, */) rescue []
    outpatient_diagnosis = ConceptName.find_by_name("DIAGNOSIS").concept
    diagnosis_concepts = ConceptClass.find_by_name("Diagnosis", :include => {:concepts => :name}).concepts rescue []
    # TODO Need to check a global property for which concept set to limit things to
    if (false)
      diagnosis_concept_set = ConceptName.find_by_name('MALAWI NATIONAL DIAGNOSIS').concept
      diagnosis_concepts = Concept.find(:all, :joins => :concept_sets, :conditions => ['concept_set = ?', concept_set.id], :include => [:name])
    end
    valid_answers = diagnosis_concepts.map{|concept|
      name = concept.fullname rescue nil
      name.match(search_string) ? name : nil rescue nil
    }.compact
    previous_answers = []
    # TODO Need to check global property to find out if we want previous answers or not (right now we)
    previous_answers = Observation.find_most_common(outpatient_diagnosis, search_string)
    @suggested_answers = (previous_answers + valid_answers).reject{|answer| filter_list.include?(answer) }.uniq[0..10]
    render :text => "<li>" + @suggested_answers.join("</li><li>") + "</li>"
  end

  def treatment
    search_string = (params[:search_string] || '').upcase
    filter_list = params[:filter_list].split(/, */) rescue []
    valid_answers = []
    unless search_string.blank?
      drugs = Drug.find(:all, :conditions => ["name LIKE ?", '%' + search_string + '%'])
      valid_answers = drugs.map {|drug| drug.name.upcase }
    end
    treatment = ConceptName.find_by_name("TREATMENT").concept
    previous_answers = Observation.find_most_common(treatment, search_string)
    suggested_answers = (previous_answers + valid_answers).reject{|answer| filter_list.include?(answer) }.uniq[0..10]
    render :text => "<li>" + suggested_answers.join("</li><li>") + "</li>"
  end

  def locations
    search_string = (params[:search_string] || 'neno').upcase
    filter_list = params[:filter_list].split(/, */) rescue []
    locations =  Location.find(:all, :select =>'name', :conditions => ["name LIKE ?", '%' + search_string + '%'])
    render :text => "<li>" + locations.map{|location| location.name }.join("</li><li>") + "</li>"
  end



  def select_options
    select_options = {
        'maternal_health_info' => [
            ['', ''],
            ['Healthcare visits', 'HEALTHCARE VISITS'],
            ['Nutrition', 'NUTRITION'],
            ['Body changes', 'BODY CHANGES'],
            ['Discomfort', 'DISCOMFORT'],
            ['Concerns', 'CONCERNS'],
            ['Emotions', 'EMOTIONS'],
            ['Warning signs', 'WARNING SIGNS'],
            ['Routines', 'ROUTINES'],
            ['Beliefs', 'BELIEFS'],
            ['Baby\'s growth', 'BABY\'S GROWTH'],
            ['Milestones', 'MILESTONES'],
            ['Prevention', 'PREVENTION'],
            ['Family planning','FAMILY PLANNING'],
            ['Birth planning - male','BIRTH PLANNING MALE'],
            ['Birth planning - female','BIRTH PLANNING FEMALE'],
            ['Other','OTHER']
        ],
        'maternal_health_symptoms' => [
            ['',''],
            ['Vaginal Bleeding during pregnancy','VAGINAL BLEEDING DURING PREGNANCY'],
            ['Postnatal bleeding','POSTNATAL BLEEDING'],
            ['Fever during pregnancy','FEVER DURING PREGNANCY SYMPTOM'],
            ['Postnatal fever','POSTNATAL FEVER SYMPTOM'],
            ['Headaches','HEADACHES'],
            ['Fits or convulsions','FITS OR CONVULSIONS SYMPTOM'],
            ['Swollen hands or feet','SWOLLEN HANDS OR FEET SYMPTOM'],
            ['Paleness of the skin and tiredness','PALENESS OF THE SKIN AND TIREDNESS SYMPTOM'],
            ['No fetal movements','NO FETAL MOVEMENTS SYMPTOM'],
            ['Water breaks','WATER BREAKS SYMPTOM'],
            ['Postnatal discharge - bad smell','POSTNATAL DISCHARGE BAD SMELL'],
            ['Abdominal pain','ABDOMINAL PAIN'],
            ['Problems with monthly periods','PROBLEMS WITH MONTHLY PERIODS'],
            ['Problems with family planning method','PROBLEMS WITH FAMILY PLANNING METHOD'],
            ['Infertility','INFERTILITY'],
            ['Frequent miscarriages','FREQUENT MISCARRIAGES'],
            ['Vaginal bleeding (not during pregnancy)','VAGINAL BLEEDING NOT DURING PREGNANCY'],
            ['Vaginal itching','VAGINAL ITCHING'],
            ['Vaginal discharge ','VAGINAL DISCHARGE'],
            ['Other','OTHER']
        ],
        #TODO - add the new symptoms above, danger signs below on to concept server
        'danger_signs' => [
            ['',''],
            ['Heavy vaginal bleeding during pregnancy','HEAVY VAGINAL BLEEDING DURING PREGNANCY'],
            ['Excessive postnatal bleeding','EXCESSIVE POSTNATAL BLEEDING'],
            ['Fever during pregnancy','FEVER DURING PREGNANCY SIGN'],
            ['Postanatal fever','POSTNATAL FEVER SIGN'],
            ['Severe headache','SEVERE HEADACHE'],
            ['Fits or convulsions','FITS OR CONVULSIONS SIGN'],
            ['Swollen hands, feet, and face','SWOLLEN HANDS OR FEET SIGN'],
            ['Paleness of the skin and tiredness','PALENESS OF THE SKIN AND TIREDNESS SIGN'],
            ['No fetal movements','NO FETAL MOVEMENTS SIGN'],
            ['Water breaks','WATER BREAKS SIGN'],
            ['Severe abdominal pain','ACUTE ABDOMINAL PAIN']
        ],
        'child_health_info' => [
            ['',''],
            ['Sleeping','SLEEPING'],
            ['Feeding problems','FEEDING PROBLEMS'],
            ['crying','CRYING'],
            ['Bowel movements','BOWEL MOVEMENTS'],
            ['Skin rashes','SKIN RASHES'],
            ['Skin infections','SKIN INFECTIONS'],
            ['Umbilicus infection','UMBILICUS INFECTION'],
            ['Growth milestones','GROWTH MILESTONES'],
            ['Accessing healthcare services','ACCESSING HEALTHCARE SERVICES'],
            #        ['Family planning','Family planning'],
            ['Other','OTHER']
        ],
        'type_of_message_content' => [
            ['',''],
            ['Pregnancy', 'Pregnancy'],
            ['Postnatal', 'Postnatal'],
            ['Child', 'Child'],
            ['WCBA', 'WCBA'],
            #['Family planning', 'Family planning'], #TODO check if the reports will work well after adding this to the list
            ['Observer', 'Observer']
        ],
        'message_type' => [
            ['', ''],
            ['SMS', 'SMS'],
            ['Voice','VOICE']
        ],
        'phone_type' => [
            ['', ''],
            ['Community phone', 'COMMUNITY PHONE'],
            ['Personal phone', 'PERSONAL PHONE'],
            ['Family member phone', 'FAMILY MEMBER PHONE'],
            ['Neighbour\'s phone', 'NEIGHBOUR\'S PHONE'] #TODO check if this will work
        ],
        'language_type' => [
            ['', ''],
            ['Chichewa', 'CHICHEWA'],
            ['Chiyao', 'CHIYAO']
        ],
        'pregnancy_status' => [
            ['', ''],
            ['Pregnant', 'Pregnant'],
            ['NOT pregnant', 'NOT pregnant'],
            ['Delivered', 'Delivered'],
            ['Miscarried', 'Miscarried']
        ],
        'child_danger_signs_greater_zero_outcome' => [
            ['Referred to a health centre', 'REFERRED TO A HEALTH CENTRE'],
            ['Hospital', 'HOSPITAL'],
            ['Referred to nearest village clinic', 'REFERRED TO NEAREST VILLAGE CLINIC'],
            ['Given advice', 'GIVEN ADVICE'],
            ['Nurse consultation', 'NURSE CONSULTATION'],
            ['Registered for Tips and reminders','REGISTERED FOR TIPS AND REMINDERS' ], #'REGISTERED FOR TIPS AND REMINDERS']
            ['Referral to emergency transport','REFERRAL TO EMERGENCY TRANSPORT' ],
            ['Other','OTHER' ] #'REGISTERED FOR TIPS AND REMINDERS']
        ],
        'child_symptoms_greater_zero_outcome' => [
            ['Referred to nearest village clinic', 'REFERRED TO NEAREST VILLAGE CLINIC'],
            ['Referred to a health centre', 'REFERRED TO A HEALTH CENTRE'],
            ['Hospital', 'HOSPITAL'],
            ['Given advice', 'GIVEN ADVICE'],
            ['Nurse consultation', 'NURSE CONSULTATION'],
            ['Registered for Tips and reminders','REGISTERED FOR TIPS AND REMINDERS' ], #'REGISTERED FOR TIPS AND REMINDERS']
            ['Referral to emergency transport','REFERRAL TO EMERGENCY TRANSPORT' ],
            ['Other','OTHER' ] #'REGISTERED FOR TIPS AND REMINDERS']
        ],
        'general_outcome' => [
            ['Given advice', 'GIVEN ADVICE'],
            ['Referred to nearest village clinic', 'REFERRED TO NEAREST VILLAGE CLINIC'],
            ['Referred to a health centre', 'REFERRED TO A HEALTH CENTRE'],
            ['Hospital', 'HOSPITAL'],
            ['Nurse consultation', 'NURSE CONSULTATION'],
            ['Registered for Tips and reminders','REGISTERED FOR TIPS AND REMINDERS' ], #'REGISTERED FOR TIPS AND REMINDERS'],
            ['Referral to emergency transport','REFERRAL TO EMERGENCY TRANSPORT' ],
            ['Other','OTHER' ]
        ],
        'referral_reasons' => [
            ['',''],
            ['Danger signs observed', 'DANGER SIGNS OBSERVED'],
            ['Physical exam needed', 'PHYSICAL EXAM NEEDED'],
            ['Village clinic not accessible', 'VILLAGE CLINIC NOT ACCESSIBLE'],
            ['Follow-up on previous treatment', 'FOLLOW-UP ON PREVIOUS TREATMENT'],
            ['No health center or Hospital referral', 'NO HEALTH CENTER OR HOSPITAL REFERRAL'],
            ['Other', 'OTHER']
        ],

        'reason_for_not_attending_anc' => [
            ['',''],
            ['Clinic too far','Clinic too far'],
            ['No time to go','No time to go'],
            ['Poor care at clinic','Poor care at clinic'],
            ['Too early in pregnancy','Too early in pregnancy'],
            ['Did not know I should go','Did not know I should go'],
            ['HSA unable to visit client','HSA unable to visit client'],
            ['HSA cannot find client','HSA cannot find client'],
            ['Client died','Client died'],
            ['Client miscarried','Client miscarried'],
            ['Client delivered','Client delivered'],
            ['Client moved','Client moved'],
            ['Other','Other']
        ],

        'reason_for_not_visiting_anc_client' => [
            ['',''],
            ['HSA too busy','HSA too busy'],
            ['HSA Cannot find client','HSA Cannot find client'],
            ['Client moved','Client moved'],
            ['Client miscarried','Client miscarried'],
            ['Client delivered','Client delivered'],
            ['Client died','Client died'],
            ['Other','Other']
        ]
    }
  end



end
