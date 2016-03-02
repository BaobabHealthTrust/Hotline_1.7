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

  def new_hsa
    @person = Person.new
  end

  def search_hsa
    unless request.get
      person = PersonName.find_by_name(params[:person]['names']['given_name'], params[:person]['names']['family_name'])
      redirect_to '/manage_user'
    end
  end
  
  def edit_hsa
    render :layout => false
  end

  def create_hsa
    person = Person.create(birthdate: Date.today, birthdate_estimated: 1, gender: params[:person]['gender'])

    person_attribute = PersonAttribute.create(person_id: person.id,
     person_attribute_type_id: PersonAttributeType.where("name = 'Health Surveillance Assistant'").first.person_attribute_type_id)

    person_name = PersonName.create(given_name: params[:person]['names']['given_name'], 
      family_name: params[:person]['names']['family_name'], person_id: person.id)

    PersonNameCode.create(given_name_code: person_name.given_name.soundex, 
      family_name_code: person_name.family_name.soundex, person_name_id: person_name.id)

    #Person.create(person_id: person.id, gender: params[:person]['gender'], birthdate: params[:person]['birthdate'])

    redirect_to '/manage_user'

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

























  #def create_hsa
    # person_name = PersonName.create(given_name: params[:person]['names']['given_name'], 
    #   family_name: params[:person]['names']['family_name'], person_id: person.id)

    # person = Person.create(birthdate: Date.today, birthdate_estimated: 1, gender: params[:person]['gender']) 

    # PersonNameCode.create(given_name_code: person_name.given_name.soundex, 
    #   family_name_code: person_name.family_name.soundex, person_name_id: person_name.id)
    
    # People.create(given_name: params[:people]['given_name'], family_name: params[:people]['family_name'], 
    #  given_name_code: params[:given_name_code][person_name.given_name.soundex], 
    #  family_name_code: params[:family_name_code][person_name.family_name.soundex], 
    #  gender: params[:people]['gender'], birthdate: params[:people]['birthdate'], 
    #  birthdate_estimated: params[:people]['birthdate_estimated']) 

    # redirect_to '/manage_user'
    
   #end
