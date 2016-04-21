class Observation < ActiveRecord::Base
  self.table_name = 'obs'

  include Openmrs

  default_scope { where(voided: 0) }

  belongs_to :encounter, -> {where voided: 0}, class_name: "Encounter", foreign_key: "encounter_id"
  belongs_to :order, -> {where voided: 0}
  belongs_to :concept, -> {where retired: 0}
  belongs_to :concept_name, -> {where voided: 0}, class_name: "ConceptName", foreign_key: "concept_id"
  belongs_to :answer_concept, -> {where retired: 0}, class_name: "Concept", foreign_key: "value_coded"
  belongs_to :answer_concept_name, -> {where voided: 0}, class_name: "ConceptName", foreign_key: "value_coded_name_id"
  has_many :concept_names, through: :concept

  def to_s(tags=[])
    formatted_name = self.concept_name.typed(tags, self.concept_name.concept_id).name rescue nil
    formatted_name ||= self.concept_name.name rescue nil
    formatted_name ||= self.concept.concept_names.typed(tags, self.concept_name.concept_id).first.name || self.concept.fullname rescue nil
    formatted_name ||= self.concept.concept_names.first.name rescue 'Unknown concept name'
    "#{formatted_name}:  #{self.answer_string(tags)}"
  end

  def name(tags=[])
    formatted_name = self.concept_name.tagged(tags).name rescue nil
    formatted_name ||= self.concept_name.name rescue nil
    formatted_name ||= self.concept.concept_names.tagged(tags).first.name rescue nil
    formatted_name ||= self.concept.concept_names.first.name rescue 'Unknown concept name'
    "#{self.answer_string(tags)}"
  end

  def answer_string(tags=[])

    value = ConceptName.where(concept_id: self.value_coded).first.name rescue nil
    if value.blank?
      value = self.value_datetime.to_time.strftime('%d/%b/%Y %H:%M:%S') rescue nil
    end

    if value.blank?
      value = self.value_numeric rescue nil
    end

    if value.blank?
      value = self.value_text rescue nil
    end

    value
  end

  def self.by_concept_today(person_id, concept_name, date = Date.today)

    concept_id = ConceptName.find_by_name(concept_name).concept_id
    return "Concept Not Found!!" if concept_id.blank?
    return 'Patient Not Found!!' if Patient.find(person_id).blank?

    last_enc = Encounter.find_by_sql("
    SELECT encounter.encounter_id FROM encounter
        INNER JOIN obs ON obs.person_id = encounter.patient_id AND obs.concept_id = #{concept_id}
      WHERE patient_id = #{person_id} AND DATE(encounter.encounter_datetime) <= '#{date.to_s(:db)}'
      ORDER BY encounter_datetime DESC LIMIT 1"
    )
    return [] if last_enc.length == 0

    last_enc_id = last_enc.last.encounter_id
    Observation.find_by_sql(
        "SELECT * FROM obs WHERE person_id = #{person_id} AND encounter_id = #{last_enc_id}
          AND concept_id = #{concept_id} AND DATEDIFF('#{date.to_s(:db)}', DATE(obs_datetime)) <= 9*30
          ORDER BY obs_datetime DESC LIMIT 5 ").collect{|o| o.answer_string}.delete_if{|a| a.blank?}.uniq
  end


end
