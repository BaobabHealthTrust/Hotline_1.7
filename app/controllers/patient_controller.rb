class PatientController < ApplicationController
  def dashboard
    
    @tab_name = params[:tab_name] 
    @tab_name = 'current_call' if @tab_name.blank?
    @patient_obj = PatientService.get_patient(params[:patient_id])
    #render :layout => false
  end

  def search_result

    unless params[:action_type] == 'new_client'
      @given_name = params[:person]['names']['given_name'].squish.split(' ')[0]
      @family_name = params[:person]['names']['given_name'].squish.split(' ')[1] || ''

      params[:person]['names']['given_name'] = @given_name
      params[:person]['names']['family_name'] = @family_name
      @gender = params[:person]['gender']
    else
      @given_name = params[:person]['names']['given_name']
      @family_name = params[:person]['names']['family_name']
      @gender = params[:person]['gender']
    end

    flash[:missing_family_name] = "Family Name can not be blank, please include patient family name."
    @people = PatientService.find_by_demographics(params)
    render :layout => false
  end

  def new
    flash[:age_max_digits] = 'Incorrect Input! Age should have a maximum of 3 digits.'
    flash[:age_out_of_range] = 'Incorrect Input! Age should be between 0 and 150.'
    flash[:age_blank] = 'Incorrect Input! Age can not be blank.'
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

  def given_name_plus_family_name
    search("given_name_plus_family_name", params[:search_string],params[:gender])
  end

  def attributes_search_results
    @people = []
    (Person.where('person_id > 1') || []).each do |person|
      @people << PatientService.get_patient(person.id)
    end

    @attribute_name = params[:attribute_name].titleize
    @attribute = params[:attribute_value]
    render :layout => false
  end

  def districts
    location_tag = LocationTag.find_by_name("District")
    @districts = Location.where("m.location_tag_id = #{location_tag.id}").joins("INNER JOIN location_tag_map m
     ON m.location_id = location.location_id").collect{|l | [l.id, l.name]}
    @location_names = @districts.collect { |location_id, location_name| location_name}
    @call_modes = [""] + GlobalProperty.find_by(:description => "call.modes").property_value.split(",")
  end

  def pregnancy_status
        
  end

  

  private

  def search(field_name, search_string, gender = nil)
    case field_name
      when 'given_name'
        @names = PersonName.where("c.given_name_code LIKE(?)", "%#{search_string.soundex}%").joins("INNER JOIN person_name_code c 
          ON c.person_name_id = person_name.person_name_id").group(:given_name).limit(30).collect do |rec| 
            rec.given_name
        end
      when 'family_name'
        @names = PersonName.where("c.family_name_code LIKE(?)", "%#{search_string.soundex}%").joins("INNER JOIN person_name_code c 
          ON c.person_name_id = person_name.person_name_id").group(:family_name).limit(30).collect do |rec| 
            rec.family_name
        end
      when 'given_name_plus_family_name'
        given_name_code = search_string.squish.split(' ')[0].soundex rescue ''
        family_name_code = search_string.squish.split(' ')[1].soundex rescue ''
        family_name_code = given_name_code if family_name_code.blank?

        @names = PersonName.where("(c.given_name_code LIKE(?) OR c.family_name_code LIKE(?)) AND p.gender=?", 
          "%#{given_name_code}%","%#{family_name_code}%",gender.first).joins("INNER JOIN person_name_code c 
          ON c.person_name_id = person_name.person_name_id INNER JOIN person p 
          ON p.person_id = person_name.person_id").group(:family_name).limit(30).collect do |rec| 
            [rec.given_name, rec.family_name]
        end
        render :text => "<li>" + @names.map{|f,l| "#{f} #{l}" } .join("</li><li>") + "</li>" and return
    end
    render :text => "<li>" + @names.map{|n| n } .join("</li><li>") + "</li>"
  end

end
