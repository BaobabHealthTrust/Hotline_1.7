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

  def new
    @user = User.new
    #roles = UserRole.all.map(&:role)
  end

  def edit_hsa
    render :layout => false
  end

  def create
    #raise params.inspect
    people = People.create(gender: params[:people]['gender'])  
    person = Person.create(given_name: params[:person]['names']['given_name'], 
    family_name: params[:person]['names']['family_name'], person_id: person.id)

    PersonNameCode.create(given_name_code: person_name.given_name.soundex, 
      family_name_code: person_name.family_name.soundex, person_name_id: person_name.id)
    # people = people.create(.............)

     redirect_to '/manage_user'
  end

  def districts
    location_tag = LocationTag.find_by_name("District")
    @districts = Location.where("m.location_tag_id = #{location_tag.id}").joins("INNER JOIN location_tag_map m
     ON m.location_id = location.location_id").collect{|l | [l.id, l.name]}
    @location_names = @districts.collect { |location_id, location_name| location_name}
    @call_modes = [""] + GlobalProperty.find_by(:description => "call.modes").property_value.split(",")
  end

end
