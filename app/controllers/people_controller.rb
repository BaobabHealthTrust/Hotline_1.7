class PeopleController < ApplicationController
  def demographics
    @patient_obj = PatientService.get_patient(params[:patient_id])
    render :layout => false
  end

  def get_patient_names(patient_id)
      patient_names = PersonName.where(person_id: patient_id).first
      return patient_names
  end

  def get_patient_addresses(patient_id)
    patient_addresses = PersonAddress.where(person_id: patient_id).first
    return patient_addresses
  end

  def get_patient_attributes(patient_id)
    patient_attributes = PersonAttribute.where(person_id: patient_id).first
    return patient_attributes
  end

  def update_patient_names(names)
    names.save
  end

  def update_patient(patient)
    patient.save
  end

  def update_attributes(patient_attributes)
    patient_attributes.save
  end

  def demographic_modify
    if request.post?
      #------ get records for patient -----
      patient = Person.find(params[:patient_id])
      patient_names = get_patient_names(patient.person_id)
      patient_addresses = get_patient_addresses(patient.person_id)
      patient_attributes = get_patient_attributes(patient.person_id)

      case params[:field]
        #------ set names -------------------------
        when 'name'
          patient_names.given_name = params[:given_name]
          patient_names.family_name = params[:family_name]

        #------ set person (gender) -----------------
        when 'sex'
          patient.gender = params[:gender] unless params[:gender].blank?

        #------ set person(birthdate) ----------------
        when 'age'
          birthdate = PatientService.format_birthdate_params(params[:person])
          patient.birthdate = birthdate[0].to_date

        #------- set addresses ---------------------
        when 'region'
          patient_addresses.region = params[:addresses][:address2]

        when 'district'
          patient_addresses.state_province = params[:addresses][:address2]

        when 'ta'
          patient_addresses.township_division = params[:addresses][:county_district]

        when 'location'
          patient_addresses.city_village = params[:addresses][:city_village]

        #------- set attributes --------------------
        when 'phone_numbers'
          patient_attributes.value = params[:person][:phone_numbers]
      end

      #------ save modified records --------
      update_patient(patient)
      update_patient_names(patient_names)
      update_attributes(patient_attributes)

      redirect_to "/demographics/#{patient.person_id}"
    else
      @edit_page = params[:field]
      @patient_obj = PatientService.get_patient(params[:patient_id])
    end
  end

  def new_hsa
    @person = Person.new
  end

  def search_hsa
    unless request.get?
      #raise params.inspect
      family_name = params[:person]['names']['family_name']
      given_name = params[:person]['names']['given_name']
      gender = params[:person][:gender]
      @person = PersonName.where(family_name: family_name, given_name: given_name).first
      #raise @person.inspect
      redirect_to "/people/edit_hsa/#{@person.id}"
    end
  end


   def select_hsa
     render :layout => true
   end

  def edit_hsa
    #raise params.inspect
    @person = Person.find(params[:person_id])
  end


  def update_hsa
    person = Person.find(params[:person_id])
    person.update_attribute(:gender, params[:person]['gender'].first)
    person_name = PersonName.where(person_id: person.person_id).first
    person_name.update_attributes(:given_name => params[:person]['names']['given_name'],
      :family_name => params[:person]['names']['family_name'] )

    birthdate = PatientService.format_birthdate_params(params[:person])
    person.update_attributes(birthdate: birthdate[0].to_date, birthdate_estimated: birthdate[1])

    if params[:person]['cell_phone_number']
      attribute_type = PersonAttributeType.find_by_name('Cell phone number')
      person_attribute = PersonAttribute.where(person_id: person.id,
        person_attribute_type_id: attribute_type.id)

      if person_attribute.blank?
        PersonAttribute.create(value: params[:person]['cell_phone_number'],
          person_id: person.id, person_attribute_type_id: attribute_type.id)
      else
        person_attribute.first.update_attributes(value: params[:person]['cell_phone_number'])
      end
    end
    # params[:person_name] = params[:person][:names]
    # @person = Person.where(person_id: params[:person_id]).first
    # raise params[:person]['names']['given_name'].inspect
    # PersonName.update_attributes(person: params[:person]['names']['family_name'])

    # unless params[:person]['names']['family_name'].blank?
    # @person.update_attributes(person: params[:person]['names']['family_name'])
    # end unless params[:person].blank?

    # PersonName.where(person_id: @person.person_id).each do | person_name |
    #   person_name.update_attributes(void_reason: 'Edited name', voided: true)
    # end 

    # new_name = PersonName.create(given_name: params[:person]['names']['given_name'],
    #   family_name: params[:person]['names']['family_name'])
    
    # PersonNameCode.create(given_name_code: new_name.given_name.soundex,
    #   family_name_code: new_name.family_name.soundex, person_name_id: new_name.id)
    
    redirect_to '/manage_user'
  end


  def create_hsa
    
    birthdate = PatientService.format_birthdate_params(params[:person])
    person = Person.create(birthdate: birthdate[0].to_date, birthdate_estimated: birthdate[1], 
      gender: params[:person]['gender'].first)

    person_attribute = PersonAttribute.create(person_id: person.id,
      value: params[:person]['cell_phone_number'],
     person_attribute_type_id: PersonAttributeType.where("name = 'Health Surveillance Assistant'").first.person_attribute_type_id)

    person_name = PersonName.create(given_name: params[:person]['names']['given_name'], 
      family_name: params[:person]['names']['family_name'], person_id: person.id)

    PersonNameCode.create(given_name_code: person_name.given_name.soundex, 
      family_name_code: person_name.family_name.soundex, person_name_id: person_name.id)
    
    # unless params[:person]['cell_phone_number'].blank?
    #   person_attribute_type = PersonAttributeType.find_by_name('Health Surveillance Assistant')
    #   PersonAttribute.create(value: params[:person]['cell_phone_number'], 
    #     person_id: person.id, person_attribute_type_id: person_attribute_type.id)
    # end

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

  def hsa_list
    person_attribute_type = PersonAttributeType.find_by_name('Health surveillance assistant')
    @people = Person.where("a.person_attribute_type_id = ?",
      person_attribute_type.id).joins("INNER JOIN person_attribute a USING(person_id)")
    render :layout => false
  end 

  def hsa_dashboard
    @person = Person.find(params[:person_id])
  end

  def edit_selected_hsa
    redirect_to "/people/edit_hsa/#{params[:person_id]}" 
  end

end
