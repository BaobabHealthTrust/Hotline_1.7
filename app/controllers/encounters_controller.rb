class EncountersController < ApplicationController

  def create
=begin
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
=end


    @patient = Patient.find(params[:encounter][:patient_id])

    redirect_to "patient/dashboard/#{@patient.id}/tasks"  unless params[:encounter]

    # Encounter handling

    encounter = Encounter.new(params[:encounter])
    encounter.save

    # Observation handling
    (params[:observations] || []).each do |observation|

      next if observation[:concept_name].blank?

      # Check to see if any values are part of this observation
      # This keeps us from saving empty observations
      values = ['coded_or_text', 'coded_or_text_multiple', 'group_id', 'boolean', 'coded', 'drug', 'datetime', 'numeric', 'modifier', 'text'].map{|value_name|
        observation["value_#{value_name}"] unless observation["value_#{value_name}"].blank? rescue nil
      }.compact

      next if values.length == 0

      observation[:encounter_id] = encounter.id
      observation[:obs_datetime] = encounter.encounter_datetime || Time.now()
      observation[:person_id] ||= encounter.patient_id
      # Handle multiple select
      if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(Array)
        observation[:value_coded_or_text_multiple].compact!
        observation[:value_coded_or_text_multiple].reject!{|value| value.blank?}
      end
      if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(Array) && !observation[:value_coded_or_text_multiple].blank?
        values = observation.delete(:value_coded_or_text_multiple)
        values.each{|value| observation[:value_coded_or_text] = value;
        Observation.create(observation) }
      else
        observation.delete(:value_coded_or_text_multiple)
        Observation.create(observation)
      end
    end
    # Go to the next task in the workflow (or dashboard)
    redirect_to "patient/dashboard/#{@patient.id}/tasks"
  end

  def new

    @patient = Patient.find(params[:patient_id] || session[:patient_id])
    encounter_type = params[:encounter_type].humanize

    case encounter_type
      when 'Pregnancy status'
        @pregnancy_options = concept_set('Pregnancy status')
      when 'Female symptoms'
        @maternal_health_symptoms = concept_set('Maternal health symptoms')
        @danger_signs = concept_set('Danger signs')
    end

    render :action => params[:encounter_type] if params[:encounter_type]
  end

  def select_options(encounter)
    encounter_name = encounter.humanize


  end

  def concept_set(concept_name)
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
