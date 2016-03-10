class EncountersController < ApplicationController

  def create

    @patient = Patient.find(params[:encounter][:patient_id])

    redirect_to "/patient/dashboard/#{@patient.id}/tasks"  unless params[:encounter]

    encounter = Encounter.new(params[:encounter].to_h)
    encounter.location_id = session[:location_id]
    encounter.creator = session[:user_id]
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
    end
    # Go to the next task in the workflow (or dashboard)
    redirect_to "/patient/dashboard/#{@patient.id}/tasks"
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
     paramz.delete(key) if !paramz[key].blank?
    end

    Observation.create(paramz)
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
        @maternal_health_info = concept_set('Maternal health info')
      when 'Update outcomes'
        @general_outcomes = concept_set('General outcome')
      when 'Reminders'
        @phone_types = concept_set('Phone Type')
        @message_types = concept_set('Message Type')
        @language_types = concept_set('Language Type')
        @content_types = concept_set('Type of message content')
    end

    render :action => params[:encounter_type] if params[:encounter_type]
  end

  def concept_set(concept_name)
    concept = ConceptName.where(name: concept_name).first.concept
    [''] + (concept.concept_sets || []).collect do |set|
      name = ConceptName.find_by_concept_id(set.concept_set).name rescue nil
      next if name.blank?
      [name]
    end
  end

end
