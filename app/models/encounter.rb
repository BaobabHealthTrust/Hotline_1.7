
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
                     ORDER BY encounter_datetime DESC LIMIT 1", Date.today])
    .first.observations rescue []).each do |observation|
      data[observation.concept_name.name.upcase.strip] = [] if data[observation.concept_name.name.upcase.strip].blank?
      data[observation.concept_name.name.upcase.strip] << observation.answer_string
    end

    data
  end

end
