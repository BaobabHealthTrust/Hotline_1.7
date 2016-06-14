class EncountersController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create

    @patient = Patient.find(params[:encounter][:patient_id])
    @patient_obj = PatientService.get_patient(@patient.patient_id)

    redirect_to "/patient/dashboard/#{@patient.id}/tasks"  unless params[:encounter]

    encounter = Encounter.new(params[:encounter].to_h)
    encounter.location_id = session[:location_id]
    encounter.creator = session[:user_id]
    encounter.save

    # Observation handling

    if (encounter.type.name.downcase rescue false) == "dietary assessment"
      create_dietary_assess_obs(encounter, params)
      redirect_to  "/encounters/nutrition_summary?patient_id=#{@patient.id}&auto_flow=true" and return
      #redirect_to  "/encounters/new/update_outcomes?patient_id=#{@patient.id}&show_summary=true" and return
    end

    attrs = PersonAttributeType.all.inject({}){|result, k| result[k.name.upcase] = k.name; result }

    (params[:observations] || []).each do |observation|

      next if observation[:concept_name].blank?

      if observation[:value_coded_or_text] == 'Record purpose of call'
        redirect_to "/encounters/new/purpose_of_call?patient_id=#{@patient.patient_id}&confirm_purpose=true" and return
      end

      # Check to see if any values are part of this observation
      # This keeps us from saving empty observations
      values = ['coded_or_text', 'coded_or_text_multiple', 'group_id', 'boolean', 'coded', 'drug', 'datetime', 'numeric', 'modifier', 'text'].map{|value_name|
        observation["value_#{value_name}"] unless observation["value_#{value_name}"].blank? rescue nil
      }.compact
      next if values.length == 0

      concept_id = ConceptName.find_by_name(observation[:concept_name]).concept_id rescue (
        raise "Missing concept name : '#{observation[:concept_name]}', Please add it in the configurations files or call help desk line")

      next if concept_id.blank?

      observation[:concept_id] = concept_id
      observation[:encounter_id] = encounter.id
      observation[:obs_datetime] = encounter.encounter_datetime || Time.now()
      observation[:person_id] ||= encounter.patient_id
      observation[:location_id] = session[:location_id]
      observation[:creator] = session[:user_id]
      # Handle multiple select
      if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(Array)
        observation[:value_coded_or_text_multiple].compact!
        observation[:value_coded_or_text_multiple].reject!{|value| value.blank?}
      end
      if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(Array) && !observation[:value_coded_or_text_multiple].blank?
        observation[:value_coded_or_text_multiple].each{|value|
          next if value.blank?
          observation[:value_coded_or_text] = value
        create_obs(observation.to_h)
        }
      else
        create_obs(observation.to_h)
      end

      #handle available attributes
      attrs["TELEPHONE NUMBER"] = 'Cell Phone Number'

      if attrs.keys.include?(observation[:concept_name].upcase.strip)
        attr_type = PersonAttributeType.find_by_name(attrs[observation[:concept_name].upcase])

        PersonAttribute.create(
            :person_attribute_type_id => attr_type.id,
            :person_id => @patient.id,
            :creator => session[:user_id],
            :date_created => DateTime.now,
            :value => observation[:value_numeric] || observation[:value_text] || observation[:value_datetime] || observation[:value_coded_or_text]
        )
      end
      if observation[:value_coded_or_text] == 'Advice given, not registered' || observation[:value_coded_or_text] == 'Irrelevant' || observation[:value_coded_or_text] == 'Dropped' 
        redirect_to "/" and return
      end

      if params[:show_summary] == 'true'
        redirect_to "/encounters/nutrition_summary?patient_id=#{@patient.id}" and return
      end
    end

    #handle a few attributes[]
    #create relationship if provided
    if params[:guardian_id]
      rel_type = RelationshipType.where(:a_is_to_b => 'Patient', :b_is_to_a => 'Guardian').first
      rel = Relationship.new()
      rel.relationship = rel_type.id
      rel.person_a = @patient.id
      rel.person_b = params[:guardian_id]
      rel.date_created = DateTime.now.to_s(:db)
      rel.creator = session[:user_id]
      rel.save
    end

    if (encounter.type.name.downcase rescue false) == "clinical assessment"
      redirect_to  "/encounters/new/dietary_assessment?patient_id=#{@patient.id}" and return #if Encounter.current_data('DIETARY ASSESSMENT', @patient.id).blank?
    end

    if params[:show_summary]
      redirect_to "/encounters/nutrition_summary?patient_id=#{@patient.id}" and return
    end

    if !params[:end_call].blank?
      session[:end_call] = true
    end 

    # if params[:confirm_purpose].present?
    #   redirect_to '/' and return
    # end

    # Go to the next task in the workflow (or dashboard)
    age = @patient_obj.age
    #raise session[:end_call].inspect
    if (age <= 5 || age >= 13 && age <= 50 && @patient_obj.sex == 'F') && session[:automatic_flow] == true
      redirect_to next_task(@patient_obj)
    elsif params[:encounter_type] == 'Update outcomes' && session[:end_call] == true
       redirect_to '/' and return
    elsif session[:end_call] == true
        redirect_to "/encounters/new/update_outcomes?patient_id=#{@patient.id}&confirm_purpose=#{params[:confirm_purpose]}" and return
    elsif params[:confirm_purpose] == 'true'
        redirect_to '/' and return
    else
      redirect_to "/patient/dashboard/#{@patient.id}/tasks"
    end
  end

  def create_obs(paramz)

    if !paramz['value_coded_or_text'].blank?
      value = ConceptName.find_by_name(paramz['value_coded_or_text']) rescue nil
      if value.blank?
        paramz.delete('value_coded')
        paramz['value_text'] = paramz['value_coded_or_text']
      else
        paramz['value_coded'] = value.concept_id
        paramz['value_coded_name_id'] = value.id
      end
    end

    ['value_coded_or_text_multiple', 'value_coded_or_text', 'concept_name'].each do |key|
          paramz.delete(key) if paramz.has_key?(key)
    end

    Observation.create(paramz) rescue nil
  end


  def create_guardian

    patient_obj = PatientService.get_patient(params[:patient_id])

    rel_type = RelationshipType.where(:a_is_to_b => 'Patient', :b_is_to_a => 'Guardian').first
    rel = Relationship.new()
    rel.relationship = rel_type.id
    rel.person_a = params[:patient_id]
    rel.person_b = params[:guardian_id]
    rel.date_created = DateTime.now.to_s(:db)
    rel.creator = session[:user_id]
    rel.save

    session[:tag_encounters] = true
    session[:tagged_encounters_patient_id] = params[:patient_id]

    redirect_to next_task(patient_obj) and return
  end

  def new
    params[:encounter_type] = 'female_symptoms' if params[:encounter_type] == 'maternal_health_symptoms'
    params[:encounter_type] = 'update_outcomes' if params[:encounter_type] == 'update_outcome'
    @patient_obj = PatientService.get_patient(params[:patient_id] || session[:patient_id])
    @client = Patient.find(@patient_obj.patient_id)
    encounter_type = params[:encounter_type].humanize
    @age = @patient_obj.age

    case encounter_type
      when 'Pregnancy status'
        @pregnancy_options = concept_set('Pregnancy status')
        current_lmp = Observation.by_concept_today(@patient_obj.patient_id,
                                               'Last menstrual period',
                                               'Pregnancy Status',
                                               Date.today)
        current_lmp_str = current_lmp[0].split('/') rescue []
        current_lmp_str_time = current_lmp_str[2].split(' ') rescue []
        months = Date::MONTHNAMES
        shortnames = Date::ABBR_MONTHNAMES

        @current_lmp_day = current_lmp_str[0]
        @current_lmp_month = months[shortnames.index(current_lmp_str[1])]
        @current_lmp_year = current_lmp_str_time[0]

        @pregnancy_options = concept_set('Pregnancy status')
        current_delivery_date = Observation.by_concept_today(@patient_obj.patient_id,
                                                   'Delivery date',
                                                   'Pregnancy Status',
                                                   Date.today)
        current_delivery_date_str = current_delivery_date[0].split('/') rescue []
        current_delivery_date_str_time = current_delivery_date_str[2].split(' ') rescue []

        @current_delivery_date_day = current_delivery_date_str[0]
        @current_delivery_date_month = months[shortnames.index(current_delivery_date_str[1])]
        @current_delivery_date_year = current_delivery_date_str_time[0]

      when 'Female symptoms'
          #if child
        if @patient_obj.age <= 5
          @health_info = concept_set('Child health info')
          @danger_signs = concept_set('Child danger signs greater zero outcome')
          @health_symptoms = concept_set('Child health symptoms')
          @symptom_concept = "Child Health Symptoms"
          @info_concept = "Child Health Info"
        elsif (!((@patient_obj.sex.match('F') && @patient_obj.age > 13 && @patient_obj.age < 50) || @patient_obj.age <= 5))
          @health_symptoms = concept_set('General health symptoms') + ["Other"]
          @symptom_concept = "Health Symptom"
        else
          @health_info = concept_set('Maternal health info')
          @danger_signs = concept_set('Danger signs')
          @health_symptoms = concept_set('Maternal health symptoms')
          @symptom_concept = "Maternal Health Symptoms"
          @info_concept = "Maternal Health Info"
        end
      when 'Follow up'
          @follow_up_outcomes = [ "",
            "Client cannot be reached",
            "Condition improved",
            "Condition worsened",
            "Client deceased",
            "Client followed-up with referral",
            "Client did not follow up with referral",
            "Client followed advice given",
            "Client did not follow advice given"
          ]
      when 'Update outcomes'
          @encounter_type = encounter_type
          @general_outcomes = concept_set('General outcome')
          #raise params[:confirm_purpose].inspect

      when 'Reminders'
        @phone_types = concept_set('Phone Type')
        @message_types = concept_set('Message Type')
        @language_types = concept_set('Language Type')
        @content_types = (concept_set('Type of message content') - [['Postnatal'], ['Observer'], ['Wcba']] + [['WCBA']]).uniq
        @guardian = current_guardian(params[:guardian_id], @patient_obj.patient_id)

      when 'Purpose of call'
        @purpose_of_call_options = purpose_of_call_options

      when 'Confirm purpose of call'
        @confirm_call_options = call_options

      when 'Clinical assessment'
        @clinical_questions = clinical_questions#('Group 2')
        @danger_signs = ["", "Mouth sores, thrush or difficulty swallowing", "Not able to eat or drink",
        "Persistent fatigue/weakness", "Pallor of palms, nails", "Symptoms of wasting (loss of muscle, fat, visible ribs)",
        "Symptoms of underweight or overweight", "Dull, dry, thin or discolored hair", "Convulsions",
        "Hypoglycemia/Low blood sugar", "Difficult or rapid breathing or increased pulse rate", "Severe dehydration",
        "Dry or flaking skin/extensive skin lesions", "None"]
        @breast_feeding_conditions = ["", "Blocked nose", "Cleft lip or palate", "Sick/recovering", "Thrush", "Other", "None"]
        @current_pregnancy_status = Encounter.current_data("PREGNANCY STATUS", @patient_obj.patient_id)

      when 'Dietary assessment'
        @meal_types = ['', 'Breakfast', 'Lunch', 'Supper', 'Snack']
        @meal_types = {
            'group 1' => ['', 'Breakfast', 'Lunch', 'Supper', 'Snack'],
            'group 2' => ['', 'Breakfast', 'Lunch', 'Supper', 'Snack'],
            'group 3' => ['', 'Breakfast', 'Lunch', 'Supper', 'Snack'],
            'group 4' => [''],
            'group 5' => ['', 'Breakfast', 'Lunch', 'Supper', 'Snack'],
            'group 6' => ['', 'Breakfast', 'Lunch', 'Supper', 'Snack'],
            'group 7' => ['', 'Breakfast', 'Lunch', 'Supper', 'Snack']
        }
        @example_foods = {
            'Staples' => '(cereal grains, etc.)',
            'Legumes & Nuts' => '(groundnuts, etc.)',
            'Animal Foods' => '(meat, eggs, etc)',
            'Fruits' => '(citrus fruits,  etc.)',
            'Vegetables' => '(bonongwe, chisoso, etc)',
            'Fats' => '(oils, etc.)'
        }
        @food_types = {
            'group 1' => ['Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats'],
            'group 2' => ['Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats'],
            'group 3' => ['Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats'],
            'group 4' => ['Breastmilk', 'Foods', 'Other Liquids'],
            'group 5' => ['Breastmilk', 'Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats'],
            'group 6' => ['Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats'],
            'group 7' => ['Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats']
        }

        @consumption_method = ['', 'Yes', 'No']

        @preselect_options = Encounter.formatted_dietary_assessment(@patient_obj.patient_id)
      when 'Summary'
        encounter_id = EncounterType.find_by_name('Clinical Assessment').encounter_type_id
        @observations = Observation.where(person_id: @patient_obj.patient_id, encounter_id: encounter_id)
        #@current_encounter_names = @clinical_answers.collect{|e| e.type.name.upcase}
        #raise @clinical_answers.inspect
        @group = @client.nutrition_module
        render 'encounters/summary', :layout => false and return
    end

    render :action => params[:encounter_type] if params[:encounter_type]
  end

  def clinical_questions#(group)
      clinical_questions = [
         'Group 1' => [
             'Fever',
             'Diarrhea',
             'Vomiting',
             'HIV-positive',
             'TB/Tuberculosis',
             'High blood pressure/hypertension',
             'Previously diagnosed as malnourished',
             'None'
         ],
         'Group 2' => [
             'Anaemia',
             'BP/Hypertension',
             'Diarrhoea',
             'Fever',
             'HIV positive/exposed',
             'Previously diagnosed as malnourished',
             'TB/Tuberculosis',
             'Vomiting',
             'None'
         ],
         'Group 3' => [
             'Fever',
             'Diarrhea',
             'Vomiting',
             'HIV-positive',
             'TB/Tuberculosis',
             'High blood pressure/hypertension',
             'Previously diagnosed as malnourished',
             'None'
         ],
         'Group 4' => [
             'Anaemia',
             'BP/Hypertension',
             'HIV positive/exposed',
             'Previously diagnosed as moderate/severely malnourished',
             'Conditions interfering with breastfeeding',
             'TB/Tuberculosis',
             'None'
      ],
         'Group 5' => [
             'HIV-positive',
             'anaemic',
             'TB/Tuberculosis',
             'Previously diagnosed as malnourished',
             'Danger signs',
             'Conditions interfering with breastfeeding',
             'None'
         ],
         'Group 6' => [
             'HIV-positive',
             'anaemic',
             'TB/Tuberculosis',
             'previously diagnosed as malnourished',
             'None'
         ],
         'Group 7' => [
             'Fever',
             'Diarrhea',
             'Vomiting',
             'HIV-positive',
             'TB/Tuberculosis',
             'High blood pressure/hypertension',
             'Previously diagnosed as malnourished',
             'None'
         ]
      ]
      return clinical_questions[0]
  end

  def current_guardian(guardian_id=nil, patient_id=nil)
    if guardian_id
      return Person.find(guardian_id) rescue nil
    end

    #search for guardian created same day
    rel_type = RelationshipType.where(:a_is_to_b => 'Patient', :b_is_to_a => 'Guardian').first
    rel = Relationship.where(:relationship => rel_type.id, :person_a => patient_id).order("date_created DESC").first

    if rel
      return Person.find(rel.person_b) if rel.date_created.to_date == Date.today
    end
    return nil
  end

  def purpose_of_call_options
    options = ['Maternal and child health - general advice',
               'Maternal and child health - symptoms',
               'Reproductive health (not pregnant) - general advice',
               'Reproductive health (not pregnant) - symptoms',
               'HIV - general advice',
               'HIV - symptoms',
               'TB - general advice',
               'TB - symptoms',
               'Nutrition',
               'Registration'].sort + ['Other']
  end

  def call_options
    options = ['Record purpose of call',
               'Advice given, not registered',
               'Irrelevant',
               'Dropped']
  end

  def  create_dietary_assess_obs(enc, paramz)
    meal_type_concept = (@group.downcase == 'group 4') ? 'Number of Times Per Day' : 'Meal Type'
    meal_type_values = (@group.downcase == 'group 4') ? paramz['times_per_day'] : paramz['meal_type']

    food_type_concept = ConceptName.find_by_name('Food Type').concept_id
    meal_type_concept = ConceptName.find_by_name(meal_type_concept).concept_id
    consumption_method_concept = ConceptName.find_by_name('Typically Eaten').concept_id

    ((0 .. paramz['consumption_method'].length - 1)).each do |index|
      meal_type = meal_type_values[index.to_s] rescue next
      food_types = paramz['food_type'][index.to_s] rescue next
      consumption_method = paramz['consumption_method'][index.to_s] rescue next

      next if (meal_type.blank? || food_types.blank? || consumption_method.blank?)

      obs = [{
        'encounter_id' => enc.id,
        'person_id' => enc.patient_id,
        'value_coded_or_text' => meal_type,
        'concept_id' => meal_type_concept,
        'value_complex' => index.to_s,
        'obs_datetime' => enc.encounter_datetime
      }]

      food_types.each do |type|
        obs << {
            'encounter_id' => enc.id,
            'person_id' => enc.patient_id,
            'value_coded_or_text' => type,
            'concept_id' => food_type_concept,
            'value_complex' => index.to_s,
            'obs_datetime' => enc.encounter_datetime
        }
      end

      obs << {
          'encounter_id' => enc.id,
          'person_id' => enc.patient_id,
          'value_coded_or_text' => consumption_method,
          'concept_id' => consumption_method_concept,
          'value_complex' => index.to_s,
          'obs_datetime' => enc.encounter_datetime
      }

      obs.each do |ob|
        create_obs(ob)
      end

    end
  end

  def nutrition_summary
    @patient_obj = PatientService.get_patient(params[:patient_id])
    @client = Patient.find(params[:patient_id])
    @clinical_data = Encounter.current_data('CLINICAL ASSESSMENT', @patient_obj.patient_id)
    @clinical_encounter = (@clinical_data['CURRENT COMPLAINTS OR SYMPTOMS'] - ['None'] || []) rescue []
    @danger_signs = (@clinical_data['DANGER SIGNS'] || []) rescue []
    @medicines = (@clinical_data['Medicines/supplements in current pregnancy'.upcase] - ['None'] || []) rescue []
    @feeding_challenges = (@clinical_data['CONDITIONS INTERFERING WITH BREASTFEEDING'] - ['None'] || []) rescue []
    @clinical_encounter_1 = []
    @clinical_encounter_2 = []

    #segmenting clinical encounter for two tables
    if (@clinical_encounter.length > 0)
      mid = (@clinical_encounter.length/2).to_i
      @clinical_encounter_1 = @clinical_encounter[0 .. (mid - 1)]
      @clinical_encounter_2 = @clinical_encounter[(mid) .. (@clinical_encounter.length)]
    elsif (@clinical_encounter.length == 1)
      @clinical_encounter_1 = @clinical_encounter
    end
    @current_pregnancy_status = Encounter.current_data("PREGNANCY STATUS", @patient_obj.patient_id)

    @clinical_encounter_2 = @clinical_encounter_2 - @clinical_encounter_1

    @dietary_encounter = Encounter.current_data('DIETARY ASSESSMENT', @patient_obj.patient_id)
    @group = @client.nutrition_module
    @symptoms_not_available = clinical_questions[@group] - @clinical_encounter - ['None']

    @consumed_groups = Encounter.current_food_groups('DIETARY ASSESSMENT', @patient_obj.patient_id).uniq

    count = @consumed_groups.count
    @comment = ""
    if count.between?(0, 2)
      @comment = "<span style='color: red;'>No diversity</span>"
    elsif count.between?(3, 4)
      @comment = "Inadequate <br /> diversification"
    elsif count >= 5
      @comment = "<span style='color: green'>Adequate <br /> diversification</span>"
    end

    infant_age = PatientService.get_infant_age(@patient_obj)
    if !infant_age.blank? && infant_age <= 6
      @comment = "Children under 6 months should be exclusively breastfed"
    end

    @groups = {
      'group 1' => ['Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats', 'Groups Cons.'],
      'group 2' => ['Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats', 'Groups Cons.'],
      'group 3' => ['Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats', 'Groups Cons.'],
      'group 4' => ['Breastmilk', 'Foods', 'Other Liquids', 'Groups Cons.'],
      'group 5' => ['Breastmilk', 'Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats', 'Groups Cons.'],
      'group 6' => ['Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats', 'Groups Cons.'],
      'group 7' => ['Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats', 'Groups Cons.']
    }

    @example_foods =  {'Staples' => [['Cereals e.g maize, starchy fruits and
                               starchy roots e.g cassava. Provide carbohydrates, proteins, fibre, vitamins and minerals'],
                                     'staple.png'],
                       'Legumes & Nuts' => [['Groundnuts, soya beans, peas, Nzama, Bambara nuts. They provide protein, fibre and energy and healthy fats. '],
                                            'leg.png'],
                       'Animal Foods' => [['All foods of animal origin e.g meat, eggs, milk products, fish, insects(Ngumbi, bwanoni).
                                        Provide important proteins, vitamins and minerals'],
                                          'animal.jpeg'],
                       'Fruits' => [['Citrus fruits e.g oranges, lemons, <i>baobab</i>; bananas, pawpaws, mangoes.
                                     Provide the body with vitamins, energy and dietary fibre'],
                                    'bananas.png'],
                       'Vegetables' => [['Green leaves and yellow vegetables e.g bonongwe, khwanya,
                              carrots, tomatoes and mushrooms.
                                        Contain minerals, water and dietary fibre'],
                                        'veg.jpg'],
                       'Fats' => [['Found in vegetable oils, nuts, seeds, avocado pears and fatty fish(batala)
                                    such as lake trout and tuna'],
                                  'beef.png'],
                       'Foods' => [['Phala', 'Nsima'], 'staple.jpeg'],
                       'Breastmilk' => [['Milk'], 'breastf.png'],
                       'Other Liquids' => [['Other liquids <br>(water, juice, dairy/goat milk, etc.)'], 'drink.jpg'],
                       'Groups Cons.' => [["<span style='font-weight: normal;'>#{@comment}</span>"], '']
    }
    render :layout => false, :template => 'encounters/summary'
  end

end
