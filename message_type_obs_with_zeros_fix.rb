#Source_db= YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['bart2']["database"]
CONN = ActiveRecord::Base.connection

def start

  #get all message type obs with zeros
  message_type_obs = []

  #get all message type obs that have 'chichewa' or 'chiyao' as value
  message_type_concept_id = 246 #ConceptName.find_by_name('Language preference').concept_id

  message_type_obs = Encounter.find_by_sql("SELECT * FROM Hotline_db.obs WHERE concept_id = 246
                                            AND value_coded IN (0) and voided = 0 order by obs_datetime")

 (message_type_obs || []).each do |arow|
   #update the obs with zeroes to voided
  update_row = "UPDATE Hotline_db.obs
   SET voided = 1,
       voided_by = '1',
       void_reason = 'On tips and reminders obs = No therefore this obs is irrelevant',
       date_voided = NOW()
   WHERE encounter_id = #{arow.encounter_id}
   AND obs_id = #{arow.obs_id}"

   CONN.execute update_row

   puts "Finished Working on message type patient_id: #{arow.person_id}"
 end

end

start
