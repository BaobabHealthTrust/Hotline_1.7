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
        redirect_to "/encounters/new/purpose_of_call?patient_id=#{@patient.patient_id}" and return
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
    
    # Go to the next task in the workflow (or dashboard)
    age = @patient_obj.age
    if age <= 5 || age >= 13 && age <= 50 && @patient_obj.sex == 'F'
      redirect_to next_task(@patient_obj)
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

    Observation.create(paramz)
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
      when 'Female symptoms'
          #if child
        if @patient_obj.age <= 5
          @health_info = concept_set('Child health info')
          @danger_signs = concept_set('Child danger signs greater zero outcome')
          @health_symptoms = concept_set('Child health symptoms')
          @symptom_concept = "Child Health Symptoms"
          @info_concept = "Child Health Info"

          #if adult
        elsif
          @health_info = concept_set('Maternal health info')
          @danger_signs = concept_set('Danger signs')
          @health_symptoms = concept_set('Maternal health symptoms')
          @symptom_concept = "Maternal Health Symptoms"
          @info_concept = "Maternal Health Info"
        end
      when 'Update outcomes'
          @general_outcomes = concept_set('General outcome')
      when 'Reminders'
        @phone_types = concept_set('Phone Type')
        @message_types = concept_set('Message Type')
        @language_types = concept_set('Language Type')
        @content_types = concept_set('Type of message content') - [['Postnatal'], ['Observer']]
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
            'Vegetables' => '',
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
             'Previously diagnosed as malnourished'
         ],
         'Group 2' => [
             'Anaemia',
             'BP/Hypertension',
             'Diarrhoea',
             'Fever',
             'HIV positive/exposed',
             'Previously diagnosed as malnourished',
             'TB/Tuberculosis',
             'Vomiting'
         ],
         'Group 3' => [
             'Fever',
             'Diarrhea',
             'Vomiting',
             'HIV-positive',
             'TB/Tuberculosis',
             'High blood pressure/hypertension',
             'Previously diagnosed as malnourished'
         ],
         'Group 4' => [
             'Anaemia',
             'BP/Hypertension',
             'HIV positive/exposed',
             'Previously diagnosed as moderate/severely malnourished',
             'Child conditions interfering with breastfeeding',
             'TB/Tuberculosis'
      ],
         'Group 5' => [
             'child HIV-positive',
             'Child anemic',
             'Child TB/Tuberculosis',
             'Child previously diagnosed as malnourished',
             'Danger signs',
             'Child conditions interfering with breastfeeding'
         ],
         'Group 6' => [
             'Child HIV-positive',
             'Child anemic',
             'Child TB/Tuberculosis',
             'Child previously diagnosed as malnourished'
         ],
         'Group 7' => [
             'Child fever',
             'Child diarrhea',
             'Child vomiting',
             'Child HIV-positive',
             'Child TB/Tuberculosis',
             'Child high blood pressure/hypertension',
             'Child previously diagnosed as malnourished'
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
               'Irrelevant',
               'Dropped']
  end

  def  create_dietary_assess_obs(enc, paramz)
    meal_type_concept = (@group.downcase == 'group 4') ? 'Number of Times Per Day' : 'Meal Type'
    meal_type_values = (@group.downcase == 'group 4') ? paramz['times_per_day'] : paramz['meal_type']

    food_type_concept = ConceptName.find_by_name('Food Type').concept_id
    meal_type_concept = ConceptName.find_by_name(meal_type_concept).concept_id
    consumption_method_concept = ConceptName.find_by_name('Consumption Method').concept_id

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
    @clinical_encounter = (Encounter.current_data('CLINICAL ASSESSMENT', @patient_obj.patient_id)['CURRENT COMPLAINTS OR SYMPTOMS'] || []) rescue []
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


    @dietary_encounter = Encounter.current_data('DIETARY ASSESSMENT', @patient_obj.patient_id)
    @group = @client.nutrition_module
    @consumed_groups = Encounter.current_food_groups('DIETARY ASSESSMENT', @patient_obj.patient_id)

    @groups = {
      'group 1' => ['Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats', 'Groups Cons.'],
      'group 2' => ['Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats', 'Groups Cons.'],
      'group 3' => ['Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats', 'Groups Cons.'],
      'group 4' => ['Breastmilk', 'Foods', 'Other Liquids'],
      'group 5' => ['Breastmilk', 'Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats'],
      'group 6' => ['Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats', 'Groups Cons.'],
      'group 7' => ['Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats', 'Groups Cons.']
    }

    @example_foods =  {'Staples' => [['Samples: Cereal grains e.g sorghum, maize, starchy fruits such
                                      plantains; starchy roots e.g cassava. They provide carbohydrates, proteins, fibre, vitamins and minerals'],
                                     'staple.png'],
                       'Legumes & Nuts' => [['Samples: Groundnuts, soya beans, peas, Nzama, Bambara nuts. They provide protein, fibre and energy and healthy fats. '],
                                            'leg.png'],
                       'Animal Foods' => [['Samples: All foods of animal origin e.g meat, eggs, milk products, fish, insects(Ngumbi, bwanoni).
                                        These provide important proteins, vitamins and minerals'],
                                          'animal.jpeg'],
                       'Fruits' => [['Samples: Citrus fruits e.g oranges, lemons, <i>baobab</i> and tangerines ; bananas, pineapples, pawpaws, mangoes.
                                     Fruits provide the body with vitamins, minerals, water, energy and dietary fibre'],
                                    'bananas.png'],
                       'Vegetables' => [['Samples: Green leafy and yellow vegetables such as bonongwe, chisoso, khwanya,
                                        nkhwani, kholowa, mpiru, carrots, tomatoes and mushrooms.
                                        Vegetables contain vitamins, minerals, water and dietary fibre'],
                                        'veg.jpg'],
                       'Fats' => [['Healthy fats are found in vegetable oils, nuts, seeds, avocado pears and fatty fish(batala)
                                    such as lake trout and tuna'],
                                  'beef.png'],
                       'Foods' => [['Phala', 'Nsima'], 'staple.jpeg'],
                       'Breastmilk' => [['Milk'], 'breastf.png'],
                       'Other Liquids' => [['?'], 'drink.jpg'],
                       'Groups Cons.' => [["<span style='font-weight: bold'>#{@consumed_groups.uniq.count}</span>"], '']
    }
    render :layout => false, :template => 'encounters/summary'
  end

end
