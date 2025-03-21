class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :check_if_logged_in, :except => ['login']
  before_filter :find_group

  protected

  def check_if_logged_in

    if session[:user_id].blank?
      respond_to do |format|
        format.html { redirect_to '/login' }
      end
    elsif not session[:user_id].blank?
      User.current = User.find(session[:user_id])
      Location.current = Location.find(session[:location_id])
    end
  end

  def find_group
    @client = Patient.find((params[:patient_id] || params[:id])) rescue nil
    return '' if @client.blank?
    @group = @client.nutrition_module rescue nil
  end


  def concept_set(concept_name)
    concept = ConceptName.where(name: concept_name).first.concept
    [''] + (concept.concept_sets || []).collect do |set|
      name = ConceptName.find_by_concept_id(set.concept_set).name rescue nil
      next if name.blank?
      [name]
    end.sort_by{|n| n}
  end

  def next_task(patient_obj)

    patient = Patient.where(:patient_id => patient_obj.patient_id).first
    return '/' if patient.blank?

    current_encounters = Encounter.current_encounters(patient_obj.patient_id)
    current_encounter_names = current_encounters.collect{|e| e.type.name.upcase}
    if(!(patient_obj.sex.match('F') && patient_obj.age > 13 && patient_obj.age < 50 || patient_obj.age <= 5))
      symptom_encounter_name = "HEALTH SYMPTOMS"
    else
      symptom_encounter_name = patient_obj.age <= 5 ?  "CHILD HEALTH SYMPTOMS" : "MATERNAL HEALTH SYMPTOMS"
    end

    tasks = [
        {'PREGNANCY STATUS' => {
          'condition' => "session[:end_call].blank? && (patient_obj.sex.match('F') && patient_obj.age > 13 && !current_encounter_names.include?('PREGNANCY STATUS'))",
          'link' => "/encounters/new/pregnancy_status?patient_id=#{patient_obj.patient_id}"
        }},
        {'HEALTH SYMPTOMS' => {
          'condition' => "session[:end_call].blank? && (patient_obj.sex.match('F') || patient_obj.age <= 5) && !current_encounter_names.include?('#{symptom_encounter_name}')",
          'link' => "/encounters/new/female_symptoms?patient_id=#{patient_obj.patient_id}"
        }},
        {'UPDATE OUTCOME' => {
           'condition' => "!current_encounter_names.include?('UPDATE OUTCOME') && ((0 .. 5).include?(patient_obj.age) || (patient_obj.sex.match('F')  &&
                              (13 .. 50).include?(patient_obj.age)))",
           'link' => "/encounters/new/update_outcomes?patient_id=#{patient_obj.patient_id}"
        }},
        {'GUARDIAN REGISTRATION' => {
            'condition' => "session[:end_call].blank? && session[:no_guardian].blank? && patient_obj.age <= 5 && #{patient.current_guardian.blank?}",
            'link' => "/people/guardian_check?action_type=guardian&patient_id=#{patient_obj.patient_id}"
        }}
     ]

    tasks.each do |tsk|
      name = tsk.keys.first
      (next unless eval(tsk[name]['condition']) == true) rescue (raise tsk[name]['condition'].inspect)
      return tsk[name]['link']
    end

    return "/" if !session[:end_call].blank?
    return "/patient/dashboard/#{patient_obj.patient_id}/tasks"
  end
  def get_staff_members_list
    staff = User.all.map{|u| ["#{u.username}", "#{u.user_id}"]}
    return staff
  end
end
