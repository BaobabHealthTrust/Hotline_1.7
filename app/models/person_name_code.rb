class PersonNameCode < ActiveRecord::Base
  self.table_name ='person_name_code'
  include Openmrs
  
  belongs_to :person_name
  
  def self.rebuild_person_name_codes
    self.delete_all
    names = PersonName.all
    names.each {|name|
      PersonNameCode.create(
        :person_name_id => name.person_name_id,
        :given_name_code => (name.given_name || '').soundex,
        :middle_name_code => (name.middle_name || '').soundex,
        :family_name_code => (name.family_name || '').soundex,
        :family_name2_code => (name.family_name2 || '').soundex,
        :family_name_suffix_code => (name.family_name_suffix || '').soundex
      ) unless (name.voided? || name.person.nil?|| name.person.voided? || name.person.patient.nil?|| name.person.patient.voided?)
    }
  end

end
