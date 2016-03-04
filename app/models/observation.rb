class Observation < ActiveRecord::Base
  self.table_name = 'obs'

  include Openmrs

  default_scope { where(voided: 0) }

  belongs_to :encounter
  belongs_to :concept


end
