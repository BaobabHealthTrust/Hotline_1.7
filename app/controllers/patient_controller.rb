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

  def given_names
    search("given_name", params[:search_string])
  end

  def family_names
    search("family_name", params[:search_string])
  end

  def search(field_name, search_string)
    case field_name
      when 'given_name'
        @names = PersonNameCode.where(:given_name_code => search_string.soundex).joins("INNER JOIN person_name n 
          ON n.person_name_id = person_name_code.person_name_id").collect do |rec| 
            rec.given_name
        end
      when 'field_name'
    end
    render :text => "<li>" + @names.map{|n| n } .join("</li><li>") + "</li>"
  end
  
end
