###################################### Encounter Type starts ##############################################################
  CSV.foreach("#{Rails.root}/app/assets/data/encouters_with_descrptions.csv", :headers => true).with_index do |row, i|
    name = row[0].strip ; des = row[1].capitalize
		next if !EncounterType.where(name: name).first.blank?
    EncounterType.create(name: name, description: des)
    puts "EncounterType ---- #{name}"
  end
###################################### Encounter Type end ##############################################################

###################################### Creating Additional Concepts starts ##############################################################
  concept_class = ConceptClass.find_by_name('Question')
  concept_datatype = ConceptDataType.create(:name => 'N/A', :hl7_abbreviation => 'ZZ',
  :description => "Not associated with a datatype (e.g., term answers, sets)")


  CSV.foreach("#{Rails.root}/app/assets/data/additional_concept_names.csv", :headers => true).with_index do |row, i|
    concept_name = row[0].strip rescue next	
    check = ConceptName.where(:name => concept_name).last
    next if !check.blank?
    concept = Concept.create(datatype_id: concept_datatype.concept_datatype_id, class_id: concept_class.concept_class_id)
    ConceptName.create(name: concept_name, concept_id: concept.concept_id, locale: 'en')
    puts "Additional concept: ---- #{concept_name}"
  end



