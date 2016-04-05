class Observation < ActiveRecord::Base
  self.table_name = 'obs'

  include Openmrs

  default_scope { where(voided: 0) }

  belongs_to :encounter, -> {where voided: 0}
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


end
