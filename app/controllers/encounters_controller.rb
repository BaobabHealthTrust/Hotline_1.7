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
      redirect_to  "/encounters/nutrition_summary?patient_id=#{@patient.id}" and return if !Encounter.current_data('UPDATE OUTCOME', @patient.id).blank?
      redirect_to  "/encounters/new/update_outcomes?patient_id=#{@patient.id}&show_summary=true" and return
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

      concept_id = ConceptName.find_by_name(observation[:concept_name]).concept_id

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
      if attrs.keys.include?(observation[:concept_name].upcase)
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
      redirect_to  "/encounters/new/update_outcomes?patient_id=#{@patient.id}&show_summary=true" and return if Encounter.current_data('UPDATE OUTCOME', @patient.id).blank?
    end

    if params[:show_summary]
      redirect_to "/encounters/nutrition_summary?patient_id=#{@patient.id}" and return
    end

    # Go to the next task in the workflow (or dashboard)
    age = @patient_obj.age
    if age >= 13 && age <= 50 && @patient_obj.sex == 'F'
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
    @patient_obj = PatientService.get_patient(params[:patient_id] || session[:patient_id])
    @client = Patient.find(@patient_obj.patient_id)
    encounter_type = params[:encounter_type].humanize
    @age = @patient_obj.age
    case encounter_type
      when 'Pregnancy status'
        @pregnancy_options = concept_set('Pregnancy status')
      when 'Female symptoms'
        @maternal_health_symptoms = concept_set('Maternal health symptoms')
          #if child
        if @patient_obj.age <= 5
          @health_info = concept_set('Child health info')
          @danger_signs = concept_set('Child danger signs greater zero outcome')
          #if adult
        elsif
          @health_info = concept_set('Maternal health info')
          @danger_signs = concept_set('Danger signs')
        end
      when 'Update outcomes'
        @general_outcomes = concept_set('General outcome')
      when 'Reminders'
        @phone_types = concept_set('Phone Type')
        @message_types = concept_set('Message Type')
        @language_types = concept_set('Language Type')
        @content_types = concept_set('Type of message content')
        @guardian = current_guardian(params[:guardian_id], @patient_obj.patient_id)
      when 'Purpose of call'
        @purpose_of_call_options = purpose_of_call_options
      when 'Confirm purpose of call'
        @confirm_call_options = call_options
      when 'Clinical assessment'
        @clinical_questions = clinical_questions#('Group 2')
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
        @food_types = {
            'group 1' => ['', 'Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats'],
            'group 2' => ['', 'Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats'],
            'group 3' => ['', 'Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats'],
            'group 4' => ['', 'Breastmilk', 'Foods', 'Other Liquids'],
            'group 5' => ['', 'Breastmilk', 'Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats'],
            'group 6' => ['', 'Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats'],
            'group 7' => ['', 'Staples', 'Legumes & Nuts', 'Animal Foods', 'Fruits', 'Vegetables', 'Fats']
        }

        @consumption_method = ['', 'Eaten', 'Drunk']
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
             'Do you have a fever?',
             'Do you have diarrhea?',
             'Have you been vomiting?',
             'Are you HIV-positive?',
             'Do you have TB/Tuberculosis?',
             'Do you have high blood pressure/hypertension?',
             'Have you been previously diagnosed by a health worker as being moderately or severely malnourished?'
         ],
         'Group 2' => [
             'Do you have a fever?',
             'Do you have diarrhea?',
             'Have you been vomiting?',
             'Are you HIV-positive?',
             'Do you have TB/Tuberculosis?',
             'Do you have high blood pressure/hypertension?',
             'Are you anemic?',
             'Have you been previously diagnosed by a health worker as being moderately or severely malnourished?'
         ],
         'Group 3' => [
             'Do you have a fever?',
             'Do you have diarrhea?',
             'Have you been vomiting?',
             'Are you HIV-positive?',
             'Do you have TB/Tuberculosis?',
             'Do you have high blood pressure/hypertension?',
             'Have you been previously diagnosed by a health worker as being moderately or severely malnourished?'
         ],
         'Group 4' => [
             'Is the child HIV-positive?',
             'Is the child anemic?',
             'Does the child have TB/Tuberculosis?',
             'Has the child been previously diagnosed by a health worker as being moderately or severely malnourished?',
             'Are you currently experiencing any of the following danger signs?',
             'Is the child currently experiencing any conditions that interfere with breastfeeding?'
         ],
         'Group 5' => [
             'Is the child HIV-positive?',
             'Is the child anemic?',
             'Does the child have TB/Tuberculosis?',
             'Has the child been previously diagnosed by a health worker as being moderately or severely malnourished?',
             'Are you currently experiencing any of the following danger signs?',
             'Are you currently experiencing any of the following danger signs?',
             'Is the child currently experiencing any conditions that interfere with breastfeeding?'
         ],
         'Group 6' => [
             'Is the child HIV-positive?',
             'Is the child anemic?',
             'Does the child have TB/Tuberculosis?',
             'Has the child been previously diagnosed by a health worker as being moderately or severely malnourished?'
         ],
         'Group 7' => [
             'Does the child have a fever?',
             'Does the child have diarrhea?',
             'Has the child been vomiting?',
             'Is the child HIV-positive?',
             'Does the child have TB/Tuberculosis?',
             'Does the child have high blood pressure/hypertension?',
             'Has the child been previously diagnosed by a health worker as being moderately or severely malnourished?'
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

  def concept_set(concept_name)
    concept = ConceptName.where(name: concept_name).first.concept
    [''] + (concept.concept_sets || []).collect do |set|
      name = ConceptName.find_by_concept_id(set.concept_set).name rescue nil
      next if name.blank?
      [name]
    end
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
               'Registration',
               'Other']
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
        'comments' => index.to_s,
        'obs_datetime' => enc.encounter_datetime
      }]

      food_types.each do |type|
        obs << {
            'encounter_id' => enc.id,
            'person_id' => enc.patient_id,
            'value_coded_or_text' => type,
            'concept_id' => food_type_concept,
            'comments' => index.to_s,
            'obs_datetime' => enc.encounter_datetime
        }
      end

      obs << {
          'encounter_id' => enc.id,
          'person_id' => enc.patient_id,
          'value_coded_or_text' => consumption_method,
          'concept_id' => consumption_method_concept,
          'comments' => index.to_s,
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
    @clinical_encounter = Encounter.current_data('CLINICAL ASSESSMENT', @patient_obj.patient_id)
    @clinical_encounter_1 = []
    @clinical_encounter_2 = []

=begin
    #segmenting clinical encounter for two tables
    if (@clinical_encounter.keys.length > 0)
      mid = (@clinical_encounter.keys.length/2).to_i
      @clinical_encounter_1 = @clinical_encounter.keys[0 .. mid]
      @clinical_encounter_2 = @clinical_encounter.keys[(mid + 1) .. (@clinical_encounter.keys.length)]
    elsif (@clinical_encounter.keys.length == 1)
      @clinical_encounter_1 = @clinical_encounter.keys
    end
=end

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

    @example_foods =  {'Staples' => ['Cereals, Starchy foods '],
                       'Legumes & Nuts' => ['Peas, Peanuts, Beans and Nuts, etc'],
                       'Animal Foods' => ['Meat, fish, eggs, liver, heart, yoghurt, cheese, etc'],
                       'Fruits' => ['Mango, guava, orange, pineapple, West Indian cherry, pawpaw'],
                       'Vegetables' => ['Callaloo, spinach, watercress, pak choy, string beans'],
                       'Fats' => ['butter, margarine, bacon, salt pork, coconut oil, fat on meat'],
                       'Foods' => ['Phala', 'Nsima'],
                       'Breastmilk' => ['Milk'],
                       'Other Liquids' => ['?'],
                       'Groups Cons.' => ["<span style='font-weight: bold'>#{@consumed_groups.uniq.count}</span>"]
    }
    render :layout => false, :template => 'encounters/summary'
  end

end
