class EncountersController < ApplicationController

  def create
    #raise params.inspect
    ####
    #### Get global Variables for encounter --------------
    current_datetime = session[:datetime].to_datetime rescue DateTime.now
    patient = Patient.find(params[:encounter][:patient_id])
    encounter_type_name = params[:encounter][:encounter_type_name]
    encounter_datetime = params[:encounter][:encounter_datetime]
    #person = params[:person] unless params[:person].blank?

    ###### Create Encounter ---------------------------
    encounter = Encounter.create(encounter_type: ConceptName.find_by_name(encounter_type_name).concept_id, patient_id: patient.id, encounter_datetime: encounter_datetime)

    #######################################################
    # e  = Encounter.create(encounter_type: ConceptName.find_by_name('Pregnancy status').concept_id, patient_id: 122,encounter_datetime: "")
    # Observation.create(concept_id:  ConceptName.find_by_name('Pregnancy status').concept_id,
    #                   person_id: e.patient_id, value_coded: ConceptName.find_by_name(params[sss].concept_id))
    #######################################################

    ##
    ##### Record Pregnancy Status Encounter ---------------
    if encounter_type_name.upcase == "PREGNANCY STATUS"
      pregnancy_status = params[:observations][:value_coded] # save pregnancy status for client
      ###### Create Observation -------------------------
      Observation.create(concept_id: ConceptName.find_by_name(encounter_type_name).concept_id, obs_datetime: current_datetime, person_id: encounter.patient_id, value_coded: ConceptName.find_by_name(pregnancy_status).concept_id)
      if pregnancy_status.upcase == "DELIVERED"
        ##
        ##### Get expected delivery date
        delivery_date = params[:delivery_date].to_datetime.to_s
        obs = Observation.where(person_id: encounter.patient_id, value_coded: ConceptName.find_by_name(pregnancy_status).concept_id).first
        obs.value_datetime = delivery_date
        obs.save
      elsif pregnancy_status.upcase == "PREGNANT"
        ##
        ##### Get last menstural period
        expected_due_date = params[:expected_due_date].to_datetime.to_s
        obs = Observation.where(person_id: encounter.patient_id, value_coded: ConceptName.find_by_name(pregnancy_status).concept_id).first
        obs.value_datetime = expected_due_date
        obs.save
      end
      redirect_to "/encounters/new/female_symptoms?patient_id=#{patient.id}"
    end

    ##
    ##### Record Female Symptoms Encounter -----------------
    if encounter_type_name.upcase == "MATERNAL HEALTH SYMPTOMS"

    end
  end

  def new
    @selected_value = []
    @select_options = select_options(params[:encounter_type])
    @patient = Patient.find(params[:patient_id] || session[:patient_id])
    render :action => params[:encounter_type] if params[:encounter_type]
  end
=begin
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
=end
 
  def select_options(encounter)
    encounter_name = encounter.gsub('_',' ').capitalize
    case encounter_name
      when 'Pregnancy status'
        concept_name = encounter_name
      when 'Female symptoms'
        concept_names = ['maternal_health_symptoms', 'danger_signs']
        concept_name = concept_names[0].gsub('_',' ').capitalize
    end
    concept = ConceptName.where(name: concept_name).first.concept
    (concept.concept_sets || []).collect do |set|
      name = ConceptName.find_by_concept_id(set.concept_set).name rescue nil
      next if name.blank?
      [name]
    end
  end

=begin
  def select_options(encounter)
    select_options = {}
    encounter_name = encounter.gsub('_',' ').capitalize
    case encounter_name
      when 'Pregnancy status'
        concept_name = encounter_name
      when 'Female symptoms'
        concept_names = ['maternal_health_symptoms', 'danger_signs']
        select_options[0] = (concept_names || []).each do |name|
          concept_name = name.gsub('_',' ').capitalize
        end
    end
    concept = ConceptName.where(name: concept_name).first.concept
    (concept.concept_sets || []).collect do |set|
      name = ConceptName.find_by_concept_id(set.concept_set).name rescue nil
      next if name.blank?
      [name]
    end
  end
=end


end
