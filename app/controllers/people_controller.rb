class PeopleController < ApplicationController
  def demographics
    @patient_obj = PatientService.get_patient(params[:patient_id])
    render :layout => false
  end

  def demographic_modify
    if request.post?
    else
      @edit_page = params[:field]
      @patient_obj = PatientService.get_patient(params[:patient_id])
    end
  end

end
