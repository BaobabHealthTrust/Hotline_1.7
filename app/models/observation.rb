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

    coded_answer_name = self.answer_concept.concept_names.typed(tags, self.value_coded).first.name rescue nil
    coded_answer_name ||= self.answer_concept.concept_names.first.name #rescue nil
    coded_name = "#{coded_answer_name} #{self.value_modifier}#{self.value_text} #{self.value_numeric}#{self.value_datetime.strftime("%d/%b/%Y") rescue nil}#{self.value_boolean && (self.value_boolean == true ? 'Yes' : 'No' rescue nil)}#{' ['+order.to_s+']' if order_id && tags.include?('order')}"
    #the following code is a hack
    #we need to find a better way because value_coded can also be a location - not only a concept

    answer = Concept.find_by_concept_id(self.value_coded).shortname rescue nil

    if answer.nil?
      answer = Concept.find_by_concept_id(self.value_coded).fullname rescue nil
    end

    if answer.nil?
      #answer = Concept.find_with_voided(self.value_coded).fullname + ' - retired'
      answer = ' - retired'
    end

    return answer.sub(/\.0$/, "")
  end


end
