module PatientService
	require 'bean'

  def self.get_patient(person_id)
    person = Person.find(person_id)
    patient = person.patient
    names = PersonName.where(:person_id => person.id).first
    attributes = PersonAttribute.where(:person_id => person.id).first
    addresses = PersonAddress.where(:person_id => person.id).first

    patient_obj = PatientBean.new(patient)
    patient_obj.patient_id = patient.id
    patient_obj.first_name = names.given_name
    patient_obj.last_name = names.family_name
    patient_obj.birthdate = self.print_birthdate(person)
    patient_obj.birthdate_estimated = person.birthdate_estimated
    patient_obj.name = "#{patient_obj.first_name} #{patient_obj.last_name}"
    patient_obj.avr_access_number = self.get_identifier(patient, 'IVR access code')
    patient_obj.age = self.age(person)
    patient_obj.sex = person.gender

    unless addresses.blank?
      patient_obj.region = addresses.region
      patient_obj.address2 = addresses.address2
      patient_obj.county_district = addresses.county_district
      patient_obj.neighborhood_cell = addresses.neighborhood_cell
    end

    patient_obj.cell_phone_number = attributes.value unless attributes.blank?

    return patient_obj
  end

  def self.add_patient_attributes(patient_obj, para)

    uuid_names = ["Occupation", "Cell Phone Number", "Office Phone Number", "Home Phone Number"]
    i = 0
    ["occupation", "cell_phone_number", "office_phone_number", "home_phone_number"].each do |name|

      next if para[:person]["#{name}"].blank?

      uuid =  ActiveRecord::Base.connection.select_one("SELECT UUID() as uuid")['uuid']
      value = para[:person]["#{name}"]
      type = PersonAttributeType.where("name = ?", uuid_names[i]).first.id
      i = i+1

      next if type.blank?

      patient_attribute = PersonAttribute.create(
          person_id: patient_obj.patient_id,
          value: value,
          creator: 1,
          person_attribute_type_id: type,
          uuid: uuid
      )
    end
  end

  def self.find_by_demographics(params)
    @people = [] 
    given_name_code = params[:person]['names']['given_name'].soundex
    family_name_code = params[:person]['names']['family_name'].soundex
    gender = params[:person]['gender'].first

    PersonName.where("c.given_name_code LIKE(?) AND c.family_name_code LIKE(?) AND p.gender = ?", 
      "%#{given_name_code}%","%#{family_name_code}%",gender).joins("INNER JOIN person_name_code c 
      ON c.person_name_id = person_name.person_name_id 
      INNER JOIN person p ON p.person_id = person_name.person_id
      INNER JOIN patient pat ON pat.patient_id = p.person_id").select('p.person_id pat_id').group("p.person_id").limit(30).collect do |rec|
        @people << self.get_patient(rec.pat_id)
    end

    return @people
  end

  def self.create(params)
    birthdate = self.format_birthdate_params(params[:person]['birthdate'])
    person = Person.create(birthdate: birthdate[0].to_date, birthdate_estimated: birthdate[1], 
             gender: params[:person]['gender'].first) 

    names = PersonName.create(given_name: params[:person]['names']['given_name'],
      family_name: params[:person]['names']['family_name'],person_id: person.id)
    PersonNameCode.create(:given_name_code => names.given_name.soundex, 
      :family_name_code => names.family_name.soundex,:person_name_id => names.id)


    avr_identifier_type = PatientIdentifierType.find_by_name('IVR access code')
    patient = Patient.create(patient_id: person.id)
    patient_avr = PatientIdentifier.create(identifier: self.next_avr_number,
      identifier_type: avr_identifier_type.id, patient_id: person.id)

    patient_obj = PatientBean.new(patient)
    patient_obj.patient_id = patient.id
    patient_obj.first_name = names.given_name
    patient_obj.last_name = names.family_name
    patient_obj.birthdate = self.print_birthdate(person)
    patient_obj.birthdate_estimated = person.birthdate_estimated
    patient_obj.name = "#{patient_obj.first_name} #{patient_obj.last_name}"
    patient_obj.avr_access_number = patient_avr.identifier
    patient_obj.age = self.age(person)

    return patient_obj
  end

  def self.get_identifier(patient, identifier_type_name)
    identifier_type = PatientIdentifierType.find_by_name(identifier_type_name)
    PatientIdentifier.where(:identifier_type => identifier_type.id, :patient_id => patient.id).first.identifier rescue nil
  end

  def self.age(person, date_created = Date.today)
    birthdate = person.birthdate; birthdate_estimated = person.birthdate_estimated 
    today = Date.today
    # This code which better accounts for leap years
    patient_age = (today.year - birthdate.year) + ((today.month - birthdate.month) + ((today.day - birthdate.day) < 0 ? -1 : 0) < 0 ? -1 : 0)

    # If the birthdate was estimated this year, we round up the age, that way if
    # it is March and the patient says they are 25, they stay 25 (not become 24)
    birth_date = birthdate
    estimate = birthdate_estimated == 1
    patient_age += (estimate && birth_date.month == 7 && birth_date.day == 1  && today.month < birth_date.month && date_created.year == today.year) ? 1 : 0
  end

  def self.print_birthdate(person)
    birthdate_estimated = person.birthdate_estimated 
    birthdate = person.birthdate

    if birthdate_estimated == 1
      if birthdate.day == 1 and birthdate.month == 7
        birthdate.strftime("??/???/%Y")
      elsif birthdate.day == 15
        birthdate.strftime("??/%b/%Y")
      elsif birthdate.day == 1 and birthdate.month == 1
        birthdate.strftime("??/???/%Y")
      else
        birthdate.strftime("%d/%b/%Y") unless birthdate.blank?
      end
    else
      birthdate.strftime("%d/%b/%Y")
    end
  end

  def self.next_avr_number
    identifier_type = PatientIdentifierType.find_by_name('IVR access code')
    last_identifier = PatientIdentifier.select("MAX(identifier) identifier").where("identifier_type = ?",identifier_type.id).first

    if last_identifier.identifier.blank?
      1.to_s.ljust(6,'0').to_i
    else
      (last_identifier.identifier.to_i + 1).to_s.ljust(6,'0').to_i
    end
  end

  def self.format_birthdate_params(birthday_params)
    if birthday_params["birth_year"] == "Unknown" and not birthday_params['age_estimate'].blank?
        birthdate = Date.new(Date.today.year - birthday_params["age_estimate"].to_i, 7, 1)
        birthdate_estimated = 1
    else
      year = birthday_params["birth_year"]
      month = birthday_params["birth_month"]
      day = birthday_params["birth_day"]

      month_i = (month || 0).to_i
      month_i = Date::MONTHNAMES.index(month) if month_i == 0 || month_i.blank?
      month_i = Date::ABBR_MONTHNAMES.index(month) if month_i == 0 || month_i.blank?

      if month_i == 0 || month == "Unknown"
        birthdate = Date.new(year.to_i,7,1)
        birthdate_estimated = 1
      elsif day.blank? || day == "Unknown" || day == 0
        birthdate = Date.new(year.to_i,month_i,15)
        birthdate_estimated = 1
      else
        birthdate = Date.new(year.to_i,month_i,day.to_i)
        birthdate_estimated = 0
      end
    end
    
    return [birthdate, birthdate_estimated] 
  end

end
