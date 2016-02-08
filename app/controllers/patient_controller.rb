class PatientController < ApplicationController
  def dashboard
    
    @tab_name = params[:tab_name] 
    @tab_name = 'current_call' if @tab_name.blank?
    @patient_obj = PatientService.get_patient(params[:patient_id])
    render :layout => false
  end

  def search_result
    @given_name = params[:person]['names']['given_name']
    @family_name = params[:person]['names']['family_name']
    @gender = params[:person]['gender']
    @people = []
    render :layout => false
  end

  def new
    @given_name = params['given_name']
    @family_name = params['family_name']
    @gender = params['gender']
    render :layout => false
  end

  def create
    patient_obj = PatientService.create(params)
    redirect_to "/patient/dashboard/#{patient_obj.patient_id}/tasks"
  end

end
