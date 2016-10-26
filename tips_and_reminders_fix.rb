#Source_db= YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['bart2']["database"]
CONN = ActiveRecord::Base.connection

def start
  $failed_language_preference = File.open("./log/blank_hotline_labguage_preference_obs.txt", "w")
	$failed_message_types = File.open("./log/blank_hotline_message_type_obs.txt", "w")

  #get all language preference obs that have 'voice' or 'sms' as value
  language_preference_concept_id = 105 #ConceptName.find_by_name('Language preference').concept_id
  voice_concept_id = 145 #ConceptName.find_by_name('Voice').concept_id
  sms_concept_id = 129 #ConceptName.find_by_name('SMS').concept_id

  language_preference_obs = []

  language_preference_obs = Encounter.find_by_sql("SELECT * FROM Hotline_1_7_development.obs WHERE concept_id = 105
                                                    AND value_coded_name_id IN (145, 129) and voided = 0 order by obs_datetime")

  message_type_obs = []

  #get all message type obs that have 'chichewa' or 'chiyao' as value
  message_type_concept_id = 246 #ConceptName.find_by_name('Language preference').concept_id
  chichewa_concept_id = 88 #ConceptName.find_by_name('Chichewa').concept_id
  chiyao_concept_id = 90 #ConceptName.find_by_name('Chiyao').concept_id

  message_type_obs = Encounter.find_by_sql("SELECT * FROM Hotline_1_7_development.obs WHERE concept_id = 246
                                            AND value_coded IN (88, 90) and voided = 0 order by obs_datetime")

  #get all language preference obs from intermediate_bare_bones
  language_pref_bare_bones = []
  language_pref_bare_bones = Encounter.find_by_sql("SELECT * FROM hotline_intermediate_bare_bones.tips_and_reminders_encounters")
#=begin
  (language_preference_obs || []).each do |arow|
    #raise arow.encounter_id.to_yaml
    language = ""
    language_pref_bare_bones.select{|patient| patient.old_enc_id.to_i == arow.encounter_id.to_i }.each do |ans_value|
      language = ans_value.language_preference
    end

    #value_concept = Encounter.find_by_sql("Select concept_id FROM Hotline_1_7_development.concept_name where name = '#{language}' LIMIT 1")
    if language == 'Chichewa'
      value_coded_concept = 88
      value_coded_name_concept = 88
    elsif language == 'Chiyao'
      value_coded_concept = 90
      value_coded_name_concept = 90
    end

    if language.blank?
      update_row = "UPDATE Hotline_1_7_development.obs SET value_coded = 'NULL', value_coded_name_id = 'NULL' WHERE encounter_id = #{arow.encounter_id} AND person_id = #{arow.person_id} AND concept_id = #{language_preference_concept_id} AND obs.obs_id = #{arow.obs_id}"
      $failed_language_preference << "Enc_id: #{arow.encounter_id}, Pat_id: #{arow.person_id}\n"
    else
      update_row = "UPDATE Hotline_1_7_development.obs SET value_coded = #{value_coded_concept}, value_coded_name_id = #{value_coded_name_concept} WHERE encounter_id = #{arow.encounter_id} AND person_id = #{arow.person_id} AND concept_id = #{language_preference_concept_id} AND obs.obs_id = #{arow.obs_id}"
    end
    CONN.execute update_row

    puts "Finished Working on language preference patient_id: #{arow.person_id}"
 end
 $failed_language_preference.close()

 (message_type_obs || []).each do |arow|
   #raise arow.encounter_id.to_yaml
   message_type = ""
   language_pref_bare_bones.select{|patient| patient.old_enc_id.to_i == arow.encounter_id.to_i }.each do |ans_value|
     message_type = ans_value.type_of_message
   end

   if message_type == 'Voice'
     mes_value_coded_concept = 145
     mes_value_coded_name_concept = 145
   elsif message_type == 'SEND SMS'
     mes_value_coded_concept = 129
     mes_value_coded_name_concept = 129
   end

   if message_type.blank?
     update_row = "UPDATE Hotline_1_7_development.obs SET value_coded = 'NULL', value_coded_name_id = 'NULL' WHERE encounter_id = #{arow.encounter_id} AND person_id = #{arow.person_id} AND concept_id = #{language_preference_concept_id} AND obs.obs_id = #{arow.obs_id}"
     $failed_message_types << "Enc_id: #{arow.encounter_id}, Pat_id: #{arow.person_id}\n"
   else
     update_row = "UPDATE Hotline_1_7_development.obs SET value_coded = #{mes_value_coded_concept}, value_coded_name_id = #{mes_value_coded_name_concept} WHERE encounter_id = #{arow.encounter_id} AND person_id = #{arow.person_id} AND concept_id = #{message_type_concept_id} AND obs.obs_id = #{arow.obs_id}"
   end
   CONN.execute update_row

   puts "Finished Working on message type patient_id: #{arow.person_id}"
 end
 $failed_message_types.close()
end

start
