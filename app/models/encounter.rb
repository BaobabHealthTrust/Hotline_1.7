
class Encounter < ActiveRecord::Base
  self.table_name = "encounter"
  include Openmrs
  default_scope { where(voided: 0) }

	belongs_to :patient 
	has_many :observations
  belongs_to :type, class_name: "EncounterType", foreign_key: "encounter_type"

  def self.current_data(name, patient_id)
    encounter_type_id  = EncounterType.find_by_name(name).id
    data = {}

    (Encounter.find_by_sql(["SELECT * FROM encounter WHERE encounter_type = #{encounter_type_id}
                     AND DATE(encounter_datetime) = ? AND patient_id = #{patient_id}
                     ", Date.today])
    .last.observations rescue []).each do |observation|
      data[observation.concept_name.name.upcase.strip] = [] if data[observation.concept_name.name.upcase.strip].blank?
      data[observation.concept_name.name.upcase.strip] << observation.answer_string
    end

    data
  end

  def self.current_food_groups(name, patient_id)
    encounter_type_id  = EncounterType.find_by_name(name).id
    concept_id = ConceptName.find_by_name("Food Type").concept_id
    data = []

    (Encounter.find_by_sql(["SELECT * FROM encounter WHERE encounter_type = #{encounter_type_id}
                     AND DATE(encounter_datetime) = ? AND patient_id = #{patient_id}
                     ", Date.today])
    .last.observations rescue []).each do |observation|
      next if observation.concept_id.to_s != concept_id.to_s
      data << observation.answer_string
    end

    data
  end

end
