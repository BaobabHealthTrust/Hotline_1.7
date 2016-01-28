namespace :ht do
  desc "ht create"

  task create: :environment do
  	db_user = YAML::load_file('config/database.yml')[Rails.env]['username']
  	db_password = YAML::load_file('config/database.yml')[Rails.env]['password']
  	db_database = YAML::load_file('config/database.yml')[Rails.env]['database']

  	system "mysqladmin create #{db_database} -u #{db_user} -p#{db_password} -v"
  end

  desc "ht migrate"
  
  task migrate: :environment do
	ActiveRecord::Schema.define(version: 0) do
	  create_table "active_list", primary_key: "active_list_id", force: true do |t|
	    t.integer  "active_list_type_id",                        null: false
	    t.integer  "person_id",                                  null: false
	    t.integer  "concept_id",                                 null: false
	    t.integer  "start_obs_id"
	    t.integer  "stop_obs_id"
	    t.datetime "start_date",                                 null: false
	    t.datetime "end_date"
	    t.string   "comments"
	    t.integer  "creator",                                    null: false
	    t.datetime "date_created",                               null: false
	    t.integer  "voided",              limit: 2,  default: 0, null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	    t.string   "uuid",                limit: 38,             null: false
	  end

	  add_index "active_list", ["active_list_type_id"], name: "active_list_type_of_active_list", using: :btree
	  add_index "active_list", ["concept_id"], name: "concept_active_list", using: :btree
	  add_index "active_list", ["creator"], name: "user_who_created_active_list", using: :btree
	  add_index "active_list", ["person_id"], name: "person_of_active_list", using: :btree
	  add_index "active_list", ["start_obs_id"], name: "start_obs_active_list", using: :btree
	  add_index "active_list", ["stop_obs_id"], name: "stop_obs_active_list", using: :btree
	  add_index "active_list", ["voided_by"], name: "user_who_voided_active_list", using: :btree

	  create_table "active_list_allergy", primary_key: "active_list_id", force: true do |t|
	    t.string  "allergy_type",        limit: 50
	    t.integer "reaction_concept_id"
	    t.string  "severity",            limit: 50
	  end

	  add_index "active_list_allergy", ["reaction_concept_id"], name: "reaction_allergy", using: :btree

	  create_table "active_list_problem", primary_key: "active_list_id", force: true do |t|
	    t.string "status",      limit: 50
	    t.float  "sort_weight", limit: 53
	  end

	  create_table "active_list_type", primary_key: "active_list_type_id", force: true do |t|
	    t.string   "name",          limit: 50,             null: false
	    t.string   "description"
	    t.integer  "creator",                              null: false
	    t.datetime "date_created",                         null: false
	    t.integer  "retired",       limit: 2,  default: 0, null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	    t.string   "uuid",          limit: 38,             null: false
	  end

	  add_index "active_list_type", ["creator"], name: "user_who_created_active_list_type", using: :btree
	  add_index "active_list_type", ["retired_by"], name: "user_who_retired_active_list_type", using: :btree

	  create_table "arv_drug", id: false, force: true do |t|
	    t.integer "drug_id", default: 0, null: false
	  end

	  create_table "arv_drugs_orders", id: false, force: true do |t|
	    t.integer  "patient_id",               null: false
	    t.integer  "encounter_id"
	    t.integer  "concept_id",   default: 0, null: false
	    t.datetime "start_date"
	  end

	  create_table "clinic_consultation_encounter", id: false, force: true do |t|
	    t.integer  "encounter_id",                  default: 0, null: false
	    t.integer  "encounter_type",                            null: false
	    t.integer  "patient_id",                    default: 0, null: false
	    t.integer  "provider_id",                   default: 0, null: false
	    t.integer  "location_id"
	    t.integer  "form_id"
	    t.datetime "encounter_datetime",                        null: false
	    t.integer  "creator",                       default: 0, null: false
	    t.datetime "date_created",                              null: false
	    t.integer  "voided",             limit: 2,  default: 0, null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	    t.string   "uuid",               limit: 38,             null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	  end

	  create_table "clinic_registration_encounter", id: false, force: true do |t|
	    t.integer  "encounter_id",                  default: 0, null: false
	    t.integer  "encounter_type",                            null: false
	    t.integer  "patient_id",                    default: 0, null: false
	    t.integer  "provider_id",                   default: 0, null: false
	    t.integer  "location_id"
	    t.integer  "form_id"
	    t.datetime "encounter_datetime",                        null: false
	    t.integer  "creator",                       default: 0, null: false
	    t.datetime "date_created",                              null: false
	    t.integer  "voided",             limit: 2,  default: 0, null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	    t.string   "uuid",               limit: 38,             null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	  end

	  create_table "cohort", primary_key: "cohort_id", force: true do |t|
	    t.string   "name",                                  null: false
	    t.string   "description",  limit: 1000
	    t.integer  "creator",                               null: false
	    t.datetime "date_created",                          null: false
	    t.integer  "voided",       limit: 2,    default: 0, null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.string   "uuid",         limit: 38,               null: false
	  end

	  add_index "cohort", ["changed_by"], name: "user_who_changed_cohort", using: :btree
	  add_index "cohort", ["creator"], name: "cohort_creator", using: :btree
	  add_index "cohort", ["uuid"], name: "cohort_uuid_index", unique: true, using: :btree
	  add_index "cohort", ["voided_by"], name: "user_who_voided_cohort", using: :btree

	  create_table "cohort_member", id: false, force: true do |t|
	    t.integer "cohort_id",  default: 0, null: false
	    t.integer "patient_id", default: 0, null: false
	  end

	  add_index "cohort_member", ["cohort_id"], name: "cohort", using: :btree
	  add_index "cohort_member", ["patient_id"], name: "patient", using: :btree

	  create_table "complex_obs", primary_key: "obs_id", force: true do |t|
	    t.integer "mime_type_id",                     default: 0, null: false
	    t.text    "urn"
	    t.text    "complex_value", limit: 2147483647
	  end

	  add_index "complex_obs", ["mime_type_id"], name: "mime_type_of_content", using: :btree

	  create_table "concept", primary_key: "concept_id", force: true do |t|
	    t.integer  "retired",        limit: 2,  default: 0, null: false
	    t.string   "short_name"
	    t.text     "description"
	    t.text     "form_text"
	    t.integer  "datatype_id",               default: 0, null: false
	    t.integer  "class_id",                  default: 0, null: false
	    t.integer  "is_set",         limit: 2,  default: 0, null: false
	    t.integer  "creator",                   default: 0, null: false
	    t.datetime "date_created",                          null: false
	    t.integer  "default_charge"
	    t.string   "version",        limit: 50
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	    t.string   "uuid",           limit: 38,             null: false
	  end

	  add_index "concept", ["changed_by"], name: "user_who_changed_concept", using: :btree
	  add_index "concept", ["class_id"], name: "concept_classes", using: :btree
	  add_index "concept", ["creator"], name: "concept_creator", using: :btree
	  add_index "concept", ["datatype_id"], name: "concept_datatypes", using: :btree
	  add_index "concept", ["retired_by"], name: "user_who_retired_concept", using: :btree
	  add_index "concept", ["uuid"], name: "concept_uuid_index", unique: true, using: :btree

	  create_table "concept_answer", primary_key: "concept_answer_id", force: true do |t|
	    t.integer  "concept_id",                default: 0, null: false
	    t.integer  "answer_concept"
	    t.integer  "answer_drug"
	    t.integer  "creator",                   default: 0, null: false
	    t.datetime "date_created",                          null: false
	    t.string   "uuid",           limit: 38,             null: false
	    t.float    "sort_weight",    limit: 53
	  end

	  add_index "concept_answer", ["answer_concept"], name: "answer", using: :btree
	  add_index "concept_answer", ["concept_id"], name: "answers_for_concept", using: :btree
	  add_index "concept_answer", ["creator"], name: "answer_creator", using: :btree
	  add_index "concept_answer", ["uuid"], name: "concept_answer_uuid_index", unique: true, using: :btree

	  create_table "concept_class", primary_key: "concept_class_id", force: true do |t|
	    t.string   "name",                     default: "", null: false
	    t.string   "description",              default: "", null: false
	    t.integer  "creator",                  default: 0,  null: false
	    t.datetime "date_created",                          null: false
	    t.integer  "retired",       limit: 2,  default: 0,  null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	    t.string   "uuid",          limit: 38,              null: false
	  end

	  add_index "concept_class", ["creator"], name: "concept_class_creator", using: :btree
	  add_index "concept_class", ["retired"], name: "concept_class_retired_status", using: :btree
	  add_index "concept_class", ["retired_by"], name: "user_who_retired_concept_class", using: :btree
	  add_index "concept_class", ["uuid"], name: "concept_class_uuid_index", unique: true, using: :btree

	  create_table "concept_complex", primary_key: "concept_id", force: true do |t|
	    t.string "handler"
	  end

	  create_table "concept_datatype", primary_key: "concept_datatype_id", force: true do |t|
	    t.string   "name",                        default: "", null: false
	    t.string   "hl7_abbreviation", limit: 3
	    t.string   "description",                 default: "", null: false
	    t.integer  "creator",                     default: 0,  null: false
	    t.datetime "date_created",                             null: false
	    t.integer  "retired",          limit: 2,  default: 0,  null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	    t.string   "uuid",             limit: 38,              null: false
	  end

	  add_index "concept_datatype", ["creator"], name: "concept_datatype_creator", using: :btree
	  add_index "concept_datatype", ["retired"], name: "concept_datatype_retired_status", using: :btree
	  add_index "concept_datatype", ["retired_by"], name: "user_who_retired_concept_datatype", using: :btree
	  add_index "concept_datatype", ["uuid"], name: "concept_datatype_uuid_index", unique: true, using: :btree

	  create_table "concept_derived", primary_key: "concept_id", force: true do |t|
	    t.text     "rule",           limit: 16777215
	    t.datetime "compile_date"
	    t.string   "compile_status"
	    t.string   "class_name",     limit: 1024
	  end

	  create_table "concept_description", primary_key: "concept_description_id", force: true do |t|
	    t.integer  "concept_id",              default: 0,  null: false
	    t.text     "description",                          null: false
	    t.string   "locale",       limit: 50, default: "", null: false
	    t.integer  "creator",                 default: 0,  null: false
	    t.datetime "date_created",                         null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.string   "uuid",         limit: 38,              null: false
	  end

	  add_index "concept_description", ["changed_by"], name: "user_who_changed_description", using: :btree
	  add_index "concept_description", ["concept_id"], name: "concept_being_described", using: :btree
	  add_index "concept_description", ["creator"], name: "user_who_created_description", using: :btree
	  add_index "concept_description", ["uuid"], name: "concept_description_uuid_index", unique: true, using: :btree

	  create_table "concept_map", primary_key: "concept_map_id", force: true do |t|
	    t.integer  "source"
	    t.string   "source_code"
	    t.string   "comment"
	    t.integer  "creator",                 default: 0, null: false
	    t.datetime "date_created",                        null: false
	    t.integer  "concept_id",              default: 0, null: false
	    t.string   "uuid",         limit: 38,             null: false
	  end

	  add_index "concept_map", ["concept_id"], name: "map_for_concept", using: :btree
	  add_index "concept_map", ["creator"], name: "map_creator", using: :btree
	  add_index "concept_map", ["source"], name: "map_source", using: :btree
	  add_index "concept_map", ["uuid"], name: "concept_map_uuid_index", unique: true, using: :btree

	  create_table "concept_name", primary_key: "concept_name_id", force: true do |t|
	    t.integer  "concept_id"
	    t.string   "name",                         default: "", null: false
	    t.string   "locale",            limit: 50, default: "", null: false
	    t.integer  "creator",                      default: 0,  null: false
	    t.datetime "date_created",                              null: false
	    t.integer  "voided",            limit: 2,  default: 0,  null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	    t.string   "uuid",              limit: 38,              null: false
	    t.string   "concept_name_type", limit: 50
	    t.integer  "locale_preferred",  limit: 2,  default: 0
	  end

	  add_index "concept_name", ["concept_id"], name: "unique_concept_name_id", using: :btree
	  add_index "concept_name", ["concept_name_id"], name: "concept_name_id", unique: true, using: :btree
	  add_index "concept_name", ["creator"], name: "user_who_created_name", using: :btree
	  add_index "concept_name", ["name"], name: "name_of_concept", using: :btree
	  add_index "concept_name", ["uuid"], name: "concept_name_uuid_index", unique: true, using: :btree
	  add_index "concept_name", ["voided_by"], name: "user_who_voided_name", using: :btree

	  create_table "concept_name_tag", primary_key: "concept_name_tag_id", force: true do |t|
	    t.string   "tag",          limit: 50,             null: false
	    t.text     "description",                         null: false
	    t.integer  "creator",                 default: 0, null: false
	    t.datetime "date_created",                        null: false
	    t.integer  "voided",       limit: 2,  default: 0, null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	    t.string   "uuid",         limit: 38,             null: false
	  end

	  add_index "concept_name_tag", ["concept_name_tag_id"], name: "concept_name_tag_id", unique: true, using: :btree
	  add_index "concept_name_tag", ["concept_name_tag_id"], name: "concept_name_tag_id_2", unique: true, using: :btree
	  add_index "concept_name_tag", ["creator"], name: "user_who_created_name_tag", using: :btree
	  add_index "concept_name_tag", ["tag"], name: "concept_name_tag_unique_tags", unique: true, using: :btree
	  add_index "concept_name_tag", ["uuid"], name: "concept_name_tag_uuid_index", unique: true, using: :btree
	  add_index "concept_name_tag", ["voided_by"], name: "user_who_voided_name_tag", using: :btree

	  create_table "concept_name_tag_map", id: false, force: true do |t|
	    t.integer "concept_name_id",     null: false
	    t.integer "concept_name_tag_id", null: false
	  end

	  add_index "concept_name_tag_map", ["concept_name_id"], name: "map_name", using: :btree
	  add_index "concept_name_tag_map", ["concept_name_tag_id"], name: "map_name_tag", using: :btree

	  create_table "concept_numeric", primary_key: "concept_id", force: true do |t|
	    t.float   "hi_absolute",  limit: 53
	    t.float   "hi_critical",  limit: 53
	    t.float   "hi_normal",    limit: 53
	    t.float   "low_absolute", limit: 53
	    t.float   "low_critical", limit: 53
	    t.float   "low_normal",   limit: 53
	    t.string  "units",        limit: 50
	    t.integer "precise",      limit: 2,  default: 0, null: false
	  end

	  create_table "concept_proposal", primary_key: "concept_proposal_id", force: true do |t|
	    t.integer  "concept_id"
	    t.integer  "encounter_id"
	    t.string   "original_text",             default: "",         null: false
	    t.string   "final_text"
	    t.integer  "obs_id"
	    t.integer  "obs_concept_id"
	    t.string   "state",          limit: 32, default: "UNMAPPED", null: false
	    t.string   "comments"
	    t.integer  "creator",                   default: 0,          null: false
	    t.datetime "date_created",                                   null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.string   "locale",         limit: 50, default: "",         null: false
	    t.string   "uuid",           limit: 38,                      null: false
	  end

	  add_index "concept_proposal", ["changed_by"], name: "user_who_changed_proposal", using: :btree
	  add_index "concept_proposal", ["concept_id"], name: "concept_for_proposal", using: :btree
	  add_index "concept_proposal", ["creator"], name: "user_who_created_proposal", using: :btree
	  add_index "concept_proposal", ["encounter_id"], name: "encounter_for_proposal", using: :btree
	  add_index "concept_proposal", ["obs_concept_id"], name: "proposal_obs_concept_id", using: :btree
	  add_index "concept_proposal", ["obs_id"], name: "proposal_obs_id", using: :btree
	  add_index "concept_proposal", ["uuid"], name: "concept_proposal_uuid_index", unique: true, using: :btree

	  create_table "concept_proposal_tag_map", id: false, force: true do |t|
	    t.integer "concept_proposal_id", null: false
	    t.integer "concept_name_tag_id", null: false
	  end

	  add_index "concept_proposal_tag_map", ["concept_name_tag_id"], name: "map_name_tag", using: :btree
	  add_index "concept_proposal_tag_map", ["concept_proposal_id"], name: "map_proposal", using: :btree

	  create_table "concept_set", primary_key: "concept_set_id", force: true do |t|
	    t.integer  "concept_id",              default: 0, null: false
	    t.integer  "concept_set",             default: 0, null: false
	    t.float    "sort_weight",  limit: 53
	    t.integer  "creator",                 default: 0, null: false
	    t.datetime "date_created",                        null: false
	    t.string   "uuid",         limit: 38,             null: false
	  end

	  add_index "concept_set", ["concept_id"], name: "idx_concept_set_concept", using: :btree
	  add_index "concept_set", ["concept_set"], name: "has_a", using: :btree
	  add_index "concept_set", ["creator"], name: "user_who_created", using: :btree
	  add_index "concept_set", ["uuid"], name: "concept_set_uuid_index", unique: true, using: :btree

	  create_table "concept_set_derived", id: false, force: true do |t|
	    t.integer "concept_id",             default: 0, null: false
	    t.integer "concept_set",            default: 0, null: false
	    t.float   "sort_weight", limit: 53
	  end

	  create_table "concept_source", primary_key: "concept_source_id", force: true do |t|
	    t.string   "name",          limit: 50, default: "", null: false
	    t.text     "description",                           null: false
	    t.string   "hl7_code",      limit: 50
	    t.integer  "creator",                  default: 0,  null: false
	    t.datetime "date_created",                          null: false
	    t.boolean  "retired",                               null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	    t.string   "uuid",          limit: 38,              null: false
	  end

	  add_index "concept_source", ["creator"], name: "concept_source_creator", using: :btree
	  add_index "concept_source", ["hl7_code", "retired"], name: "unique_hl7_code", using: :btree
	  add_index "concept_source", ["retired_by"], name: "user_who_voided_concept_source", using: :btree
	  add_index "concept_source", ["uuid"], name: "concept_source_uuid_index", unique: true, using: :btree

	  create_table "concept_state_conversion", primary_key: "concept_state_conversion_id", force: true do |t|
	    t.integer "concept_id",                           default: 0
	    t.integer "program_workflow_id",                  default: 0
	    t.integer "program_workflow_state_id",            default: 0
	    t.string  "uuid",                      limit: 38,             null: false
	  end

	  add_index "concept_state_conversion", ["concept_id"], name: "triggering_concept", using: :btree
	  add_index "concept_state_conversion", ["program_workflow_id", "concept_id"], name: "unique_workflow_concept_in_conversion", unique: true, using: :btree
	  add_index "concept_state_conversion", ["program_workflow_id"], name: "affected_workflow", using: :btree
	  add_index "concept_state_conversion", ["program_workflow_state_id"], name: "resulting_state", using: :btree
	  add_index "concept_state_conversion", ["uuid"], name: "concept_state_conversion_uuid_index", unique: true, using: :btree

	  create_table "concept_synonym", id: false, force: true do |t|
	    t.integer  "concept_id",   default: 0,  null: false
	    t.string   "synonym",      default: "", null: false
	    t.string   "locale"
	    t.integer  "creator",      default: 0,  null: false
	    t.datetime "date_created",              null: false
	  end

	  add_index "concept_synonym", ["concept_id"], name: "synonym_for", using: :btree
	  add_index "concept_synonym", ["creator"], name: "synonym_creator", using: :btree

	  create_table "concept_word", primary_key: "concept_word_id", force: true do |t|
	    t.integer "concept_id",                 default: 0,  null: false
	    t.string  "word",            limit: 50, default: "", null: false
	    t.string  "locale",          limit: 20, default: "", null: false
	    t.integer "concept_name_id",                         null: false
	  end

	  add_index "concept_word", ["concept_id"], name: "concept_word_concept_idx", using: :btree
	  add_index "concept_word", ["concept_name_id"], name: "word_for_name", using: :btree
	  add_index "concept_word", ["word"], name: "word_in_concept_name", using: :btree

	  create_table "district", primary_key: "district_id", force: true do |t|
	    t.string   "name",          default: "",    null: false
	    t.integer  "region_id",     default: 0,     null: false
	    t.integer  "creator",       default: 0,     null: false
	    t.datetime "date_created",                  null: false
	    t.boolean  "retired",       default: false, null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	  end

	  add_index "district", ["creator"], name: "user_who_created_district", using: :btree
	  add_index "district", ["region_id"], name: "region_for_district", using: :btree
	  add_index "district", ["retired"], name: "retired_status", using: :btree
	  add_index "district", ["retired_by"], name: "user_who_retired_district", using: :btree

	  create_table "drug", primary_key: "drug_id", force: true do |t|
	    t.integer  "concept_id",                    default: 0, null: false
	    t.string   "name",               limit: 50
	    t.integer  "combination",        limit: 2,  default: 0, null: false
	    t.integer  "dosage_form"
	    t.float    "dose_strength",      limit: 53
	    t.float    "maximum_daily_dose", limit: 53
	    t.float    "minimum_daily_dose", limit: 53
	    t.integer  "route"
	    t.string   "units",              limit: 50
	    t.integer  "creator",                       default: 0, null: false
	    t.datetime "date_created",                              null: false
	    t.integer  "retired",            limit: 2,  default: 0, null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	    t.string   "uuid",               limit: 38,             null: false
	  end

	  add_index "drug", ["concept_id"], name: "primary_drug_concept", using: :btree
	  add_index "drug", ["creator"], name: "drug_creator", using: :btree
	  add_index "drug", ["dosage_form"], name: "dosage_form_concept", using: :btree
	  add_index "drug", ["retired_by"], name: "user_who_voided_drug", using: :btree
	  add_index "drug", ["route"], name: "route_concept", using: :btree
	  add_index "drug", ["uuid"], name: "drug_uuid_index", unique: true, using: :btree

	  create_table "drug_ingredient", id: false, force: true do |t|
	    t.integer "concept_id",    default: 0, null: false
	    t.integer "ingredient_id", default: 0, null: false
	  end

	  add_index "drug_ingredient", ["concept_id"], name: "combination_drug", using: :btree

	  create_table "drug_order", primary_key: "order_id", force: true do |t|
	    t.integer "drug_inventory_id",                default: 0
	    t.float   "dose",                  limit: 53
	    t.float   "equivalent_daily_dose", limit: 53
	    t.string  "units"
	    t.string  "frequency"
	    t.integer "prn",                   limit: 2,  default: 0, null: false
	    t.integer "complex",               limit: 2,  default: 0, null: false
	    t.integer "quantity"
	  end

	  add_index "drug_order", ["drug_inventory_id"], name: "inventory_item", using: :btree

	  create_table "encounter", primary_key: "encounter_id", force: true do |t|
	    t.integer  "encounter_type",                            null: false
	    t.integer  "patient_id",                    default: 0, null: false
	    t.integer  "provider_id",                   default: 0, null: false
	    t.integer  "location_id"
	    t.integer  "form_id"
	    t.datetime "encounter_datetime",                        null: false
	    t.integer  "creator",                       default: 0, null: false
	    t.datetime "date_created",                              null: false
	    t.integer  "voided",             limit: 2,  default: 0, null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	    t.string   "uuid",               limit: 38,             null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	  end

	  add_index "encounter", ["changed_by"], name: "encounter_changed_by", using: :btree
	  add_index "encounter", ["creator"], name: "encounter_creator", using: :btree
	  add_index "encounter", ["encounter_datetime"], name: "encounter_datetime_idx", using: :btree
	  add_index "encounter", ["encounter_type"], name: "encounter_type_id", using: :btree
	  add_index "encounter", ["form_id"], name: "encounter_form", using: :btree
	  add_index "encounter", ["location_id"], name: "encounter_location", using: :btree
	  add_index "encounter", ["patient_id"], name: "encounter_patient", using: :btree
	  add_index "encounter", ["provider_id"], name: "encounter_provider", using: :btree
	  add_index "encounter", ["uuid"], name: "encounter_uuid_index", unique: true, using: :btree
	  add_index "encounter", ["voided_by"], name: "user_who_voided_encounter", using: :btree

	  create_table "encounter_type", primary_key: "encounter_type_id", force: true do |t|
	    t.string   "name",          limit: 50, default: "", null: false
	    t.text     "description"
	    t.integer  "creator",                  default: 0,  null: false
	    t.datetime "date_created",                          null: false
	    t.integer  "retired",       limit: 2,  default: 0,  null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	    t.string   "uuid",          limit: 38,              null: false
	  end

	  add_index "encounter_type", ["creator"], name: "user_who_created_type", using: :btree
	  add_index "encounter_type", ["retired"], name: "retired_status", using: :btree
	  add_index "encounter_type", ["retired_by"], name: "user_who_retired_encounter_type", using: :btree
	  add_index "encounter_type", ["uuid"], name: "encounter_type_uuid_index", unique: true, using: :btree

	  create_table "external_source", primary_key: "external_source_id", force: true do |t|
	    t.integer  "source",       default: 0, null: false
	    t.string   "source_code",              null: false
	    t.string   "name"
	    t.integer  "creator",      default: 0, null: false
	    t.datetime "date_created",             null: false
	  end

	  add_index "external_source", ["creator"], name: "map_ext_creator", using: :btree
	  add_index "external_source", ["source"], name: "map_ext_source", using: :btree

	  create_table "field", primary_key: "field_id", force: true do |t|
	    t.string   "name",                       default: "", null: false
	    t.text     "description"
	    t.integer  "field_type"
	    t.integer  "concept_id"
	    t.string   "table_name",      limit: 50
	    t.string   "attribute_name",  limit: 50
	    t.text     "default_value"
	    t.integer  "select_multiple", limit: 2,  default: 0,  null: false
	    t.integer  "creator",                    default: 0,  null: false
	    t.datetime "date_created",                            null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.integer  "retired",         limit: 2,  default: 0,  null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	    t.string   "uuid",            limit: 38,              null: false
	  end

	  add_index "field", ["changed_by"], name: "user_who_changed_field", using: :btree
	  add_index "field", ["concept_id"], name: "concept_for_field", using: :btree
	  add_index "field", ["creator"], name: "user_who_created_field", using: :btree
	  add_index "field", ["field_type"], name: "type_of_field", using: :btree
	  add_index "field", ["retired"], name: "field_retired_status", using: :btree
	  add_index "field", ["retired_by"], name: "user_who_retired_field", using: :btree
	  add_index "field", ["uuid"], name: "field_uuid_index", unique: true, using: :btree

	  create_table "field_answer", id: false, force: true do |t|
	    t.integer  "field_id",                default: 0, null: false
	    t.integer  "answer_id",               default: 0, null: false
	    t.integer  "creator",                 default: 0, null: false
	    t.datetime "date_created",                        null: false
	    t.string   "uuid",         limit: 38,             null: false
	  end

	  add_index "field_answer", ["answer_id"], name: "field_answer_concept", using: :btree
	  add_index "field_answer", ["creator"], name: "user_who_created_field_answer", using: :btree
	  add_index "field_answer", ["field_id"], name: "answers_for_field", using: :btree
	  add_index "field_answer", ["uuid"], name: "field_answer_uuid_index", unique: true, using: :btree

	  create_table "field_type", primary_key: "field_type_id", force: true do |t|
	    t.string   "name",         limit: 50
	    t.text     "description",  limit: 2147483647
	    t.integer  "is_set",       limit: 2,          default: 0, null: false
	    t.integer  "creator",                         default: 0, null: false
	    t.datetime "date_created",                                null: false
	    t.string   "uuid",         limit: 38,                     null: false
	  end

	  add_index "field_type", ["creator"], name: "user_who_created_field_type", using: :btree
	  add_index "field_type", ["uuid"], name: "field_type_uuid_index", unique: true, using: :btree

	  create_table "form", primary_key: "form_id", force: true do |t|
	    t.string   "name",                            default: "", null: false
	    t.string   "version",        limit: 50,       default: "", null: false
	    t.integer  "build"
	    t.integer  "published",      limit: 2,        default: 0,  null: false
	    t.text     "description"
	    t.integer  "encounter_type"
	    t.text     "template",       limit: 16777215
	    t.text     "xslt",           limit: 16777215
	    t.integer  "creator",                         default: 0,  null: false
	    t.datetime "date_created",                                 null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.integer  "retired",        limit: 2,        default: 0,  null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retired_reason"
	    t.string   "uuid",           limit: 38,                    null: false
	  end

	  add_index "form", ["changed_by"], name: "user_who_last_changed_form", using: :btree
	  add_index "form", ["creator"], name: "user_who_created_form", using: :btree
	  add_index "form", ["encounter_type"], name: "encounter_type", using: :btree
	  add_index "form", ["retired_by"], name: "user_who_retired_form", using: :btree
	  add_index "form", ["uuid"], name: "form_uuid_index", unique: true, using: :btree

	  create_table "form2program_map", id: false, force: true do |t|
	    t.integer  "program",                        null: false
	    t.integer  "encounter_type",                 null: false
	    t.integer  "creator",                        null: false
	    t.datetime "date_created",                   null: false
	    t.integer  "changed_by",                     null: false
	    t.datetime "date_changed",                   null: false
	    t.boolean  "applied",        default: false, null: false
	  end

	  add_index "form2program_map", ["changed_by"], name: "user_who_changed_form2program", using: :btree
	  add_index "form2program_map", ["creator"], name: "user_who_created_form2program", using: :btree
	  add_index "form2program_map", ["encounter_type"], name: "encounter_type", using: :btree

	  create_table "form_field", primary_key: "form_field_id", force: true do |t|
	    t.integer  "form_id",                      default: 0, null: false
	    t.integer  "field_id",                     default: 0, null: false
	    t.integer  "field_number"
	    t.string   "field_part",        limit: 5
	    t.integer  "page_number"
	    t.integer  "parent_form_field"
	    t.integer  "min_occurs"
	    t.integer  "max_occurs"
	    t.integer  "required",          limit: 2,  default: 0, null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.integer  "creator",                      default: 0, null: false
	    t.datetime "date_created",                             null: false
	    t.float    "sort_weight",       limit: 24
	    t.string   "uuid",              limit: 38,             null: false
	  end

	  add_index "form_field", ["changed_by"], name: "user_who_last_changed_form_field", using: :btree
	  add_index "form_field", ["creator"], name: "user_who_created_form_field", using: :btree
	  add_index "form_field", ["field_id"], name: "field_within_form", using: :btree
	  add_index "form_field", ["form_id"], name: "form_containing_field", using: :btree
	  add_index "form_field", ["parent_form_field"], name: "form_field_hierarchy", using: :btree
	  add_index "form_field", ["uuid"], name: "form_field_uuid_index", unique: true, using: :btree

	  create_table "formentry_archive", primary_key: "formentry_archive_id", force: true do |t|
	    t.text     "form_data",    limit: 16777215,             null: false
	    t.datetime "date_created",                              null: false
	    t.integer  "creator",                       default: 0, null: false
	  end

	  add_index "formentry_archive", ["creator"], name: "User who created formentry_archive", using: :btree

	  create_table "formentry_error", primary_key: "formentry_error_id", force: true do |t|
	    t.text     "form_data",     limit: 16777215,              null: false
	    t.string   "error",                          default: "", null: false
	    t.text     "error_details"
	    t.integer  "creator",                        default: 0,  null: false
	    t.datetime "date_created",                                null: false
	  end

	  add_index "formentry_error", ["creator"], name: "User who created formentry_error", using: :btree

	  create_table "formentry_queue", primary_key: "formentry_queue_id", force: true do |t|
	    t.text     "form_data",    limit: 16777215,             null: false
	    t.integer  "creator",                       default: 0, null: false
	    t.datetime "date_created",                              null: false
	  end

	  create_table "formentry_xsn", primary_key: "formentry_xsn_id", force: true do |t|
	    t.integer  "form_id",                                      null: false
	    t.binary   "xsn_data",      limit: 2147483647,             null: false
	    t.integer  "creator",                          default: 0, null: false
	    t.datetime "date_created",                                 null: false
	    t.integer  "archived",                         default: 0, null: false
	    t.integer  "archived_by"
	    t.datetime "date_archived"
	  end

	  add_index "formentry_xsn", ["archived_by"], name: "User who archived formentry_xsn", using: :btree
	  add_index "formentry_xsn", ["creator"], name: "User who created formentry_xsn", using: :btree
	  add_index "formentry_xsn", ["form_id"], name: "Form with which this xsn is related", using: :btree

	  create_table "global_property", primary_key: "property", force: true do |t|
	    t.text   "property_value", limit: 16777215
	    t.text   "description"
	    t.string "uuid",           limit: 38,       null: false
	  end

	  add_index "global_property", ["uuid"], name: "global_property_uuid_index", unique: true, using: :btree

	  create_table "hl7_in_archive", primary_key: "hl7_in_archive_id", force: true do |t|
	    t.integer  "hl7_source",                      default: 0, null: false
	    t.string   "hl7_source_key"
	    t.text     "hl7_data",       limit: 16777215,             null: false
	    t.datetime "date_created",                                null: false
	    t.integer  "message_state",                   default: 2
	    t.string   "uuid",           limit: 38,                   null: false
	  end

	  add_index "hl7_in_archive", ["message_state"], name: "hl7_in_archive_message_state_idx", using: :btree
	  add_index "hl7_in_archive", ["uuid"], name: "hl7_in_archive_uuid_index", unique: true, using: :btree

	  create_table "hl7_in_error", primary_key: "hl7_in_error_id", force: true do |t|
	    t.integer  "hl7_source",                      default: 0,  null: false
	    t.text     "hl7_source_key"
	    t.text     "hl7_data",       limit: 16777215,              null: false
	    t.string   "error",                           default: "", null: false
	    t.text     "error_details"
	    t.datetime "date_created",                                 null: false
	    t.string   "uuid",           limit: 38,                    null: false
	  end

	  add_index "hl7_in_error", ["uuid"], name: "hl7_in_error_uuid_index", unique: true, using: :btree

	  create_table "hl7_in_queue", primary_key: "hl7_in_queue_id", force: true do |t|
	    t.integer  "hl7_source",                      default: 0, null: false
	    t.text     "hl7_source_key"
	    t.text     "hl7_data",       limit: 16777215,             null: false
	    t.integer  "message_state",                   default: 0, null: false
	    t.datetime "date_processed"
	    t.text     "error_msg"
	    t.datetime "date_created"
	    t.string   "uuid",           limit: 38,                   null: false
	  end

	  add_index "hl7_in_queue", ["hl7_source"], name: "hl7_source", using: :btree
	  add_index "hl7_in_queue", ["uuid"], name: "hl7_in_queue_uuid_index", unique: true, using: :btree

	  create_table "hl7_source", primary_key: "hl7_source_id", force: true do |t|
	    t.string   "name",                     default: "", null: false
	    t.text     "description",  limit: 255
	    t.integer  "creator",                  default: 0,  null: false
	    t.datetime "date_created",                          null: false
	    t.string   "uuid",         limit: 38,               null: false
	  end

	  add_index "hl7_source", ["creator"], name: "creator", using: :btree
	  add_index "hl7_source", ["uuid"], name: "hl7_source_uuid_index", unique: true, using: :btree

	  create_table "htmlformentry_html_form", force: true do |t|
	    t.integer  "form_id"
	    t.string   "name",         limit: 100,                      null: false
	    t.text     "xml_data",     limit: 16777215,                 null: false
	    t.integer  "creator",                       default: 0,     null: false
	    t.datetime "date_created",                                  null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.boolean  "retired",                       default: false, null: false
	  end

	  add_index "htmlformentry_html_form", ["changed_by"], name: "User who changed htmlformentry_htmlform", using: :btree
	  add_index "htmlformentry_html_form", ["creator"], name: "User who created htmlformentry_htmlform", using: :btree
	  add_index "htmlformentry_html_form", ["form_id"], name: "Form with which this htmlform is related", using: :btree

	  create_table "liquibasechangelog", id: false, force: true do |t|
	    t.string   "ID",           limit: 63,  null: false
	    t.string   "AUTHOR",       limit: 63,  null: false
	    t.string   "FILENAME",     limit: 200, null: false
	    t.datetime "DATEEXECUTED",             null: false
	    t.string   "MD5SUM",       limit: 32
	    t.string   "DESCRIPTION"
	    t.string   "COMMENTS"
	    t.string   "TAG"
	    t.string   "LIQUIBASE",    limit: 10
	  end

	  create_table "liquibasechangeloglock", primary_key: "ID", force: true do |t|
	    t.boolean  "LOCKED",      null: false
	    t.datetime "LOCKGRANTED"
	    t.string   "LOCKEDBY"
	  end

	  create_table "location", primary_key: "location_id", force: true do |t|
	    t.string   "name",                         default: "",    null: false
	    t.string   "description"
	    t.string   "address1",          limit: 50
	    t.string   "address2",          limit: 50
	    t.string   "city_village",      limit: 50
	    t.string   "state_province",    limit: 50
	    t.string   "postal_code",       limit: 50
	    t.string   "country",           limit: 50
	    t.string   "latitude",          limit: 50
	    t.string   "longitude",         limit: 50
	    t.integer  "creator",                      default: 0,     null: false
	    t.datetime "date_created",                                 null: false
	    t.string   "county_district",   limit: 50
	    t.string   "neighborhood_cell", limit: 50
	    t.string   "region",            limit: 50
	    t.string   "subregion",         limit: 50
	    t.string   "township_division", limit: 50
	    t.boolean  "retired",                      default: false, null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	    t.integer  "location_type_id"
	    t.integer  "parent_location"
	    t.string   "uuid",              limit: 38,                 null: false
	  end

	  add_index "location", ["creator"], name: "user_who_created_location", using: :btree
	  add_index "location", ["location_type_id"], name: "type_of_location", using: :btree
	  add_index "location", ["name"], name: "name_of_location", using: :btree
	  add_index "location", ["parent_location"], name: "parent_location", using: :btree
	  add_index "location", ["retired"], name: "retired_status", using: :btree
	  add_index "location", ["retired_by"], name: "user_who_retired_location", using: :btree
	  add_index "location", ["uuid"], name: "location_uuid_index", unique: true, using: :btree

	  create_table "location_tag", primary_key: "location_tag_id", force: true do |t|
	    t.string   "name",          limit: 50
	    t.string   "description"
	    t.integer  "creator",                              null: false
	    t.datetime "date_created",                         null: false
	    t.integer  "retired",       limit: 2,  default: 0, null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	    t.string   "uuid",          limit: 38,             null: false
	  end

	  add_index "location_tag", ["creator"], name: "location_tag_creator", using: :btree
	  add_index "location_tag", ["retired_by"], name: "location_tag_retired_by", using: :btree
	  add_index "location_tag", ["uuid"], name: "location_tag_uuid_index", unique: true, using: :btree

	  create_table "location_tag_map", id: false, force: true do |t|
	    t.integer "location_id",     null: false
	    t.integer "location_tag_id", null: false
	  end

	  add_index "location_tag_map", ["location_tag_id"], name: "location_tag_map_tag", using: :btree

	  create_table "logic_rule_definition", force: true do |t|
	    t.string   "uuid",          limit: 38,                   null: false
	    t.string   "name",                                       null: false
	    t.string   "description",   limit: 1000
	    t.string   "rule_content",  limit: 2048,                 null: false
	    t.string   "language",                                   null: false
	    t.integer  "creator",                    default: 0,     null: false
	    t.datetime "date_created",                               null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.boolean  "retired",                    default: false, null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	  end

	  add_index "logic_rule_definition", ["changed_by"], name: "changed_by for rule_definition", using: :btree
	  add_index "logic_rule_definition", ["creator"], name: "creator for rule_definition", using: :btree
	  add_index "logic_rule_definition", ["name"], name: "name", unique: true, using: :btree
	  add_index "logic_rule_definition", ["retired_by"], name: "retired_by for rule_definition", using: :btree

	  create_table "logic_rule_token", primary_key: "logic_rule_token_id", force: true do |t|
	    t.integer  "creator",                                                  null: false
	    t.datetime "date_created",             default: '0002-11-30 00:00:00', null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.string   "token",        limit: 512,                                 null: false
	    t.string   "class_name",   limit: 512,                                 null: false
	    t.string   "state",        limit: 512
	    t.string   "uuid",         limit: 38,                                  null: false
	  end

	  add_index "logic_rule_token", ["changed_by"], name: "token_changed_by", using: :btree
	  add_index "logic_rule_token", ["creator"], name: "token_creator", using: :btree
	  add_index "logic_rule_token", ["uuid"], name: "logic_rule_token_uuid", unique: true, using: :btree

	  create_table "logic_rule_token_tag", id: false, force: true do |t|
	    t.integer "logic_rule_token_id",             null: false
	    t.string  "tag",                 limit: 512, null: false
	  end

	  add_index "logic_rule_token_tag", ["logic_rule_token_id"], name: "token_tag", using: :btree

	  create_table "logic_token_registration", primary_key: "token_registration_id", force: true do |t|
	    t.integer  "creator",                                                          null: false
	    t.datetime "date_created",                     default: '0002-11-30 00:00:00', null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.string   "token",               limit: 512,                                  null: false
	    t.string   "provider_class_name", limit: 512,                                  null: false
	    t.string   "provider_token",      limit: 512,                                  null: false
	    t.string   "configuration",       limit: 2000
	    t.string   "uuid",                limit: 38,                                   null: false
	  end

	  add_index "logic_token_registration", ["changed_by"], name: "token_registration_changed_by", using: :btree
	  add_index "logic_token_registration", ["creator"], name: "token_registration_creator", using: :btree
	  add_index "logic_token_registration", ["uuid"], name: "uuid", unique: true, using: :btree

	  create_table "logic_token_registration_tag", id: false, force: true do |t|
	    t.integer "token_registration_id",             null: false
	    t.string  "tag",                   limit: 512, null: false
	  end

	  add_index "logic_token_registration_tag", ["token_registration_id"], name: "token_registration_tag", using: :btree

	  create_table "merged_patients", primary_key: "patient_id", force: true do |t|
	    t.integer "merged_to_id", null: false
	  end

	  create_table "mime_type", primary_key: "mime_type_id", force: true do |t|
	    t.string "mime_type",   limit: 75, default: "", null: false
	    t.text   "description"
	  end

	  add_index "mime_type", ["mime_type_id"], name: "mime_type_id", using: :btree

	  create_table "national_id", force: true do |t|
	    t.string   "national_id", limit: 30, default: "",    null: false
	    t.boolean  "assigned",               default: false, null: false
	    t.boolean  "eds",                    default: false
	    t.integer  "creator"
	    t.datetime "date_issued"
	    t.text     "issued_to"
	  end

	  create_table "note", primary_key: "note_id", force: true do |t|
	    t.string   "note_type",    limit: 50
	    t.integer  "patient_id"
	    t.integer  "obs_id"
	    t.integer  "encounter_id"
	    t.text     "text",                                null: false
	    t.integer  "priority"
	    t.integer  "parent"
	    t.integer  "creator",                 default: 0, null: false
	    t.datetime "date_created",                        null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.string   "uuid",         limit: 38,             null: false
	  end

	  add_index "note", ["changed_by"], name: "user_who_changed_note", using: :btree
	  add_index "note", ["creator"], name: "user_who_created_note", using: :btree
	  add_index "note", ["encounter_id"], name: "encounter_note", using: :btree
	  add_index "note", ["obs_id"], name: "obs_note", using: :btree
	  add_index "note", ["parent"], name: "note_hierarchy", using: :btree
	  add_index "note", ["patient_id"], name: "patient_note", using: :btree
	  add_index "note", ["uuid"], name: "note_uuid_index", unique: true, using: :btree

	  create_table "notification_alert", primary_key: "alert_id", force: true do |t|
	    t.string   "text",             limit: 512,             null: false
	    t.integer  "satisfied_by_any",             default: 0, null: false
	    t.integer  "alert_read",                   default: 0, null: false
	    t.datetime "date_to_expire"
	    t.integer  "creator",                                  null: false
	    t.datetime "date_created",                             null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.string   "uuid",             limit: 38,              null: false
	  end

	  add_index "notification_alert", ["changed_by"], name: "user_who_changed_alert", using: :btree
	  add_index "notification_alert", ["creator"], name: "alert_creator", using: :btree
	  add_index "notification_alert", ["uuid"], name: "notification_alert_uuid_index", unique: true, using: :btree

	  create_table "notification_alert_recipient", id: false, force: true do |t|
	    t.integer   "alert_id",                            null: false
	    t.integer   "user_id",                             null: false
	    t.integer   "alert_read",              default: 0, null: false
	    t.timestamp "date_changed"
	    t.string    "uuid",         limit: 38,             null: false
	  end

	  add_index "notification_alert_recipient", ["alert_id"], name: "id_of_alert", using: :btree
	  add_index "notification_alert_recipient", ["user_id"], name: "alert_read_by_user", using: :btree

	  create_table "notification_template", primary_key: "template_id", force: true do |t|
	    t.string  "name",       limit: 50
	    t.text    "template"
	    t.string  "subject",    limit: 100
	    t.string  "sender"
	    t.string  "recipients", limit: 512
	    t.integer "ordinal",                default: 0
	    t.string  "uuid",       limit: 38,              null: false
	  end

	  add_index "notification_template", ["uuid"], name: "notification_template_uuid_index", unique: true, using: :btree

	  create_table "obs", primary_key: "obs_id", force: true do |t|
	    t.integer  "person_id",                                  null: false
	    t.integer  "concept_id",                     default: 0, null: false
	    t.integer  "encounter_id"
	    t.integer  "order_id"
	    t.datetime "obs_datetime",                               null: false
	    t.integer  "location_id"
	    t.integer  "obs_group_id"
	    t.string   "accession_number"
	    t.integer  "value_group_id"
	    t.boolean  "value_boolean"
	    t.integer  "value_coded"
	    t.integer  "value_coded_name_id"
	    t.integer  "value_drug"
	    t.datetime "value_datetime"
	    t.float    "value_numeric",       limit: 53
	    t.string   "value_modifier",      limit: 2
	    t.text     "value_text"
	    t.datetime "date_started"
	    t.datetime "date_stopped"
	    t.string   "comments"
	    t.integer  "creator",                        default: 0, null: false
	    t.datetime "date_created",                               null: false
	    t.integer  "voided",              limit: 2,  default: 0, null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	    t.string   "value_complex"
	    t.string   "uuid",                limit: 38,             null: false
	  end

	  add_index "obs", ["concept_id"], name: "obs_concept", using: :btree
	  add_index "obs", ["creator"], name: "obs_enterer", using: :btree
	  add_index "obs", ["encounter_id"], name: "encounter_observations", using: :btree
	  add_index "obs", ["location_id"], name: "obs_location", using: :btree
	  add_index "obs", ["obs_datetime"], name: "obs_datetime_idx", using: :btree
	  add_index "obs", ["obs_group_id"], name: "obs_grouping_id", using: :btree
	  add_index "obs", ["order_id"], name: "obs_order", using: :btree
	  add_index "obs", ["person_id"], name: "patient_obs", using: :btree
	  add_index "obs", ["uuid"], name: "obs_uuid_index", unique: true, using: :btree
	  add_index "obs", ["value_coded"], name: "answer_concept", using: :btree
	  add_index "obs", ["value_coded_name_id"], name: "obs_name_of_coded_value", using: :btree
	  add_index "obs", ["value_drug"], name: "answer_concept_drug", using: :btree
	  add_index "obs", ["voided_by"], name: "user_who_voided_obs", using: :btree

	  create_table "order_extension", primary_key: "order_extension_id", force: true do |t|
	    t.integer  "order_id",                                null: false
	    t.string   "value",        limit: 50, default: "",    null: false
	    t.integer  "creator",                 default: 0,     null: false
	    t.datetime "date_created",                            null: false
	    t.boolean  "voided",                  default: false, null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	  end

	  add_index "order_extension", ["creator"], name: "user_who_created_ext", using: :btree
	  add_index "order_extension", ["voided"], name: "retired_status", using: :btree
	  add_index "order_extension", ["voided_by"], name: "user_who_retired_ext", using: :btree

	  create_table "order_type", primary_key: "order_type_id", force: true do |t|
	    t.string   "name",                     default: "", null: false
	    t.string   "description",              default: "", null: false
	    t.integer  "creator",                  default: 0,  null: false
	    t.datetime "date_created",                          null: false
	    t.integer  "retired",       limit: 2,  default: 0,  null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	    t.string   "uuid",          limit: 38,              null: false
	  end

	  add_index "order_type", ["creator"], name: "type_created_by", using: :btree
	  add_index "order_type", ["retired"], name: "retired_status", using: :btree
	  add_index "order_type", ["retired_by"], name: "user_who_retired_order_type", using: :btree
	  add_index "order_type", ["uuid"], name: "order_type_uuid_index", unique: true, using: :btree

	  create_table "orders", primary_key: "order_id", force: true do |t|
	    t.integer  "order_type_id",                            default: 0, null: false
	    t.integer  "concept_id",                               default: 0, null: false
	    t.integer  "orderer",                                  default: 0
	    t.integer  "encounter_id"
	    t.text     "instructions"
	    t.datetime "start_date"
	    t.datetime "auto_expire_date"
	    t.integer  "discontinued",                  limit: 2,  default: 0, null: false
	    t.datetime "discontinued_date"
	    t.integer  "discontinued_by"
	    t.integer  "discontinued_reason"
	    t.integer  "creator",                                  default: 0, null: false
	    t.datetime "date_created",                                         null: false
	    t.integer  "voided",                        limit: 2,  default: 0, null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	    t.integer  "patient_id",                                           null: false
	    t.string   "accession_number"
	    t.integer  "obs_id"
	    t.string   "uuid",                          limit: 38,             null: false
	    t.string   "discontinued_reason_non_coded"
	  end

	  add_index "orders", ["creator"], name: "order_creator", using: :btree
	  add_index "orders", ["discontinued_by"], name: "user_who_discontinued_order", using: :btree
	  add_index "orders", ["discontinued_reason"], name: "discontinued_because", using: :btree
	  add_index "orders", ["encounter_id"], name: "orders_in_encounter", using: :btree
	  add_index "orders", ["obs_id"], name: "obs_for_order", using: :btree
	  add_index "orders", ["order_type_id"], name: "type_of_order", using: :btree
	  add_index "orders", ["orderer"], name: "orderer_not_drug", using: :btree
	  add_index "orders", ["patient_id"], name: "order_for_patient", using: :btree
	  add_index "orders", ["uuid"], name: "orders_uuid_index", unique: true, using: :btree
	  add_index "orders", ["voided_by"], name: "user_who_voided_order", using: :btree

	  create_table "patient", primary_key: "patient_id", force: true do |t|
	    t.integer  "tribe"
	    t.integer  "creator",                default: 0, null: false
	    t.datetime "date_created",                       null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.integer  "voided",       limit: 2, default: 0, null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	  end

	  add_index "patient", ["changed_by"], name: "user_who_changed_pat", using: :btree
	  add_index "patient", ["creator"], name: "user_who_created_patient", using: :btree
	  add_index "patient", ["tribe"], name: "belongs_to_tribe", using: :btree
	  add_index "patient", ["voided_by"], name: "user_who_voided_patient", using: :btree

	  create_table "patient_identifier", primary_key: "patient_identifier_id", force: true do |t|
	    t.integer  "patient_id",                 default: 0,  null: false
	    t.string   "identifier",      limit: 50, default: "", null: false
	    t.integer  "identifier_type",            default: 0,  null: false
	    t.integer  "preferred",       limit: 2,  default: 0,  null: false
	    t.integer  "location_id",                default: 0,  null: false
	    t.integer  "creator",                    default: 0,  null: false
	    t.datetime "date_created",                            null: false
	    t.integer  "voided",          limit: 2,  default: 0,  null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	    t.string   "uuid",            limit: 38,              null: false
	  end

	  add_index "patient_identifier", ["creator"], name: "identifier_creator", using: :btree
	  add_index "patient_identifier", ["identifier"], name: "identifier_name", using: :btree
	  add_index "patient_identifier", ["identifier_type"], name: "defines_identifier_type", using: :btree
	  add_index "patient_identifier", ["location_id"], name: "identifier_location", using: :btree
	  add_index "patient_identifier", ["patient_id"], name: "idx_patient_identifier_patient", using: :btree
	  add_index "patient_identifier", ["uuid"], name: "patient_identifier_uuid_index", unique: true, using: :btree
	  add_index "patient_identifier", ["voided_by"], name: "identifier_voider", using: :btree

	  create_table "patient_identifier_type", primary_key: "patient_identifier_type_id", force: true do |t|
	    t.string   "name",               limit: 50,  default: "", null: false
	    t.text     "description",                                 null: false
	    t.string   "format",             limit: 50
	    t.integer  "check_digit",        limit: 2,   default: 0,  null: false
	    t.integer  "creator",                        default: 0,  null: false
	    t.datetime "date_created",                                null: false
	    t.integer  "required",           limit: 2,   default: 0,  null: false
	    t.string   "format_description"
	    t.string   "validator",          limit: 200
	    t.integer  "retired",            limit: 2,   default: 0,  null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	    t.string   "uuid",               limit: 38,               null: false
	  end

	  add_index "patient_identifier_type", ["creator"], name: "type_creator", using: :btree
	  add_index "patient_identifier_type", ["retired"], name: "retired_status", using: :btree
	  add_index "patient_identifier_type", ["retired_by"], name: "user_who_retired_patient_identifier_type", using: :btree
	  add_index "patient_identifier_type", ["uuid"], name: "patient_identifier_type_uuid_index", unique: true, using: :btree

	  create_table "patient_program", primary_key: "patient_program_id", force: true do |t|
	    t.integer  "patient_id",                default: 0, null: false
	    t.integer  "program_id",                default: 0, null: false
	    t.datetime "date_enrolled"
	    t.datetime "date_completed"
	    t.integer  "creator",                   default: 0, null: false
	    t.datetime "date_created",                          null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.integer  "voided",         limit: 2,  default: 0, null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	    t.string   "uuid",           limit: 38,             null: false
	    t.integer  "location_id"
	  end

	  add_index "patient_program", ["changed_by"], name: "user_who_changed", using: :btree
	  add_index "patient_program", ["creator"], name: "patient_program_creator", using: :btree
	  add_index "patient_program", ["patient_id"], name: "patient_in_program", using: :btree
	  add_index "patient_program", ["program_id"], name: "program_for_patient", using: :btree
	  add_index "patient_program", ["uuid"], name: "patient_program_uuid_index", unique: true, using: :btree
	  add_index "patient_program", ["voided_by"], name: "user_who_voided_patient_program", using: :btree

	  create_table "patient_service_waiting_time", id: false, force: true do |t|
	    t.integer  "patient_id",   default: 0, null: false
	    t.date     "visit_date"
	    t.datetime "start_time"
	    t.datetime "finish_time"
	    t.time     "service_time"
	  end

	  create_table "patient_state", primary_key: "patient_state_id", force: true do |t|
	    t.integer  "patient_program_id",            default: 0, null: false
	    t.integer  "state",                         default: 0, null: false
	    t.date     "start_date"
	    t.date     "end_date"
	    t.integer  "creator",                       default: 0, null: false
	    t.datetime "date_created",                              null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.integer  "voided",             limit: 2,  default: 0, null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	    t.string   "uuid",               limit: 38,             null: false
	  end

	  add_index "patient_state", ["changed_by"], name: "patient_state_changer", using: :btree
	  add_index "patient_state", ["creator"], name: "patient_state_creator", using: :btree
	  add_index "patient_state", ["patient_program_id"], name: "patient_program_for_state", using: :btree
	  add_index "patient_state", ["state"], name: "state_for_patient", using: :btree
	  add_index "patient_state", ["uuid"], name: "patient_state_uuid_index", unique: true, using: :btree
	  add_index "patient_state", ["voided_by"], name: "patient_state_voider", using: :btree

	  create_table "patientflags_flag", primary_key: "flag_id", force: true do |t|
	    t.string   "name",                                       null: false
	    t.string   "criteria",      limit: 5000,                 null: false
	    t.string   "message",                                    null: false
	    t.boolean  "enabled",                                    null: false
	    t.string   "evaluator",                                  null: false
	    t.string   "description",   limit: 1000
	    t.integer  "creator",                    default: 0,     null: false
	    t.datetime "date_created",                               null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.boolean  "retired",                    default: false, null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	    t.string   "uuid",          limit: 38,                   null: false
	  end

	  create_table "patientflags_flag_tag", id: false, force: true do |t|
	    t.integer "flag_id", null: false
	    t.integer "tag_id",  null: false
	  end

	  add_index "patientflags_flag_tag", ["flag_id"], name: "flag_id", using: :btree
	  add_index "patientflags_flag_tag", ["tag_id"], name: "tag_id", using: :btree

	  create_table "patientflags_tag", primary_key: "tag_id", force: true do |t|
	    t.string   "tag",                                        null: false
	    t.string   "description",   limit: 1000
	    t.integer  "creator",                    default: 0,     null: false
	    t.datetime "date_created",                               null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.boolean  "retired",                    default: false, null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	    t.string   "uuid",          limit: 38,                   null: false
	  end

	  create_table "patients_for_location", primary_key: "patient_id", force: true do |t|
	  end

	  create_table "patients_to_merge", id: false, force: true do |t|
	    t.integer "patient_id"
	    t.integer "to_merge_to_id"
	  end

	  create_table "person", primary_key: "person_id", force: true do |t|
	    t.string   "gender",              limit: 50, default: ""
	    t.date     "birthdate"
	    t.integer  "birthdate_estimated", limit: 2,  default: 0,  null: false
	    t.integer  "dead",                limit: 2,  default: 0,  null: false
	    t.datetime "death_date"
	    t.integer  "cause_of_death"
	    t.integer  "creator",                        default: 0,  null: false
	    t.datetime "date_created",                                null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.integer  "voided",              limit: 2,  default: 0,  null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	    t.string   "uuid",                limit: 38,              null: false
	  end

	  add_index "person", ["birthdate"], name: "person_birthdate", using: :btree
	  add_index "person", ["cause_of_death"], name: "person_died_because", using: :btree
	  add_index "person", ["changed_by"], name: "user_who_changed_pat", using: :btree
	  add_index "person", ["creator"], name: "user_who_created_patient", using: :btree
	  add_index "person", ["death_date"], name: "person_death_date", using: :btree
	  add_index "person", ["uuid"], name: "person_uuid_index", unique: true, using: :btree
	  add_index "person", ["voided_by"], name: "user_who_voided_patient", using: :btree

	  create_table "person_address", primary_key: "person_address_id", force: true do |t|
	    t.integer  "person_id"
	    t.integer  "preferred",         limit: 2,  default: 0, null: false
	    t.string   "address1",          limit: 50
	    t.string   "address2",          limit: 50
	    t.string   "city_village",      limit: 50
	    t.string   "state_province",    limit: 50
	    t.string   "postal_code",       limit: 50
	    t.string   "country",           limit: 50
	    t.string   "latitude",          limit: 50
	    t.string   "longitude",         limit: 50
	    t.integer  "creator",                      default: 0, null: false
	    t.datetime "date_created",                             null: false
	    t.integer  "voided",            limit: 2,  default: 0, null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	    t.string   "county_district",   limit: 50
	    t.string   "neighborhood_cell", limit: 50
	    t.string   "region",            limit: 50
	    t.string   "subregion",         limit: 50
	    t.string   "township_division", limit: 50
	    t.string   "uuid",              limit: 38,             null: false
	  end

	  add_index "person_address", ["creator"], name: "patient_address_creator", using: :btree
	  add_index "person_address", ["date_created"], name: "index_date_created_on_person_address", using: :btree
	  add_index "person_address", ["person_id"], name: "patient_addresses", using: :btree
	  add_index "person_address", ["uuid"], name: "person_address_uuid_index", unique: true, using: :btree
	  add_index "person_address", ["voided_by"], name: "patient_address_void", using: :btree

	  create_table "person_attribute", primary_key: "person_attribute_id", force: true do |t|
	    t.integer  "person_id",                           default: 0,  null: false
	    t.string   "value",                    limit: 50, default: "", null: false
	    t.integer  "person_attribute_type_id",            default: 0,  null: false
	    t.integer  "creator",                             default: 0,  null: false
	    t.datetime "date_created",                                     null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.integer  "voided",                   limit: 2,  default: 0,  null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	    t.string   "uuid",                     limit: 38,              null: false
	  end

	  add_index "person_attribute", ["changed_by"], name: "attribute_changer", using: :btree
	  add_index "person_attribute", ["creator"], name: "attribute_creator", using: :btree
	  add_index "person_attribute", ["person_attribute_type_id"], name: "defines_attribute_type", using: :btree
	  add_index "person_attribute", ["person_id"], name: "identifies_person", using: :btree
	  add_index "person_attribute", ["uuid"], name: "person_attribute_uuid_index", unique: true, using: :btree
	  add_index "person_attribute", ["voided_by"], name: "attribute_voider", using: :btree

	  create_table "person_attribute_type", primary_key: "person_attribute_type_id", force: true do |t|
	    t.string   "name",           limit: 50, default: "", null: false
	    t.text     "description",                            null: false
	    t.string   "format",         limit: 50
	    t.integer  "foreign_key"
	    t.integer  "searchable",     limit: 2,  default: 0,  null: false
	    t.integer  "creator",                   default: 0,  null: false
	    t.datetime "date_created",                           null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.integer  "retired",        limit: 2,  default: 0,  null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	    t.string   "edit_privilege"
	    t.string   "uuid",           limit: 38,              null: false
	    t.float    "sort_weight",    limit: 53
	  end

	  add_index "person_attribute_type", ["changed_by"], name: "attribute_type_changer", using: :btree
	  add_index "person_attribute_type", ["creator"], name: "type_creator", using: :btree
	  add_index "person_attribute_type", ["edit_privilege"], name: "privilege_which_can_edit", using: :btree
	  add_index "person_attribute_type", ["name"], name: "name_of_attribute", using: :btree
	  add_index "person_attribute_type", ["retired"], name: "person_attribute_type_retired_status", using: :btree
	  add_index "person_attribute_type", ["retired_by"], name: "user_who_retired_person_attribute_type", using: :btree
	  add_index "person_attribute_type", ["searchable"], name: "attribute_is_searchable", using: :btree
	  add_index "person_attribute_type", ["uuid"], name: "person_attribute_type_uuid_index", unique: true, using: :btree

	  create_table "person_name", primary_key: "person_name_id", force: true do |t|
	    t.integer  "preferred",          limit: 2,  default: 0, null: false
	    t.integer  "person_id"
	    t.string   "prefix",             limit: 50
	    t.string   "given_name",         limit: 50
	    t.string   "middle_name",        limit: 50
	    t.string   "family_name_prefix", limit: 50
	    t.string   "family_name",        limit: 50
	    t.string   "family_name2",       limit: 50
	    t.string   "family_name_suffix", limit: 50
	    t.string   "degree",             limit: 50
	    t.integer  "creator",                       default: 0, null: false
	    t.datetime "date_created",                              null: false
	    t.integer  "voided",             limit: 2,  default: 0, null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.string   "uuid",               limit: 38,             null: false
	  end

	  add_index "person_name", ["creator"], name: "user_who_made_name", using: :btree
	  add_index "person_name", ["family_name"], name: "last_name", using: :btree
	  add_index "person_name", ["family_name2"], name: "family_name2", using: :btree
	  add_index "person_name", ["given_name"], name: "first_name", using: :btree
	  add_index "person_name", ["middle_name"], name: "middle_name", using: :btree
	  add_index "person_name", ["person_id"], name: "name_for_patient", using: :btree
	  add_index "person_name", ["uuid"], name: "person_name_uuid_index", unique: true, using: :btree
	  add_index "person_name", ["voided_by"], name: "user_who_voided_name", using: :btree

	  create_table "person_name_code", primary_key: "person_name_code_id", force: true do |t|
	    t.integer "person_name_id"
	    t.string  "given_name_code",         limit: 50
	    t.string  "middle_name_code",        limit: 50
	    t.string  "family_name_code",        limit: 50
	    t.string  "family_name2_code",       limit: 50
	    t.string  "family_name_suffix_code", limit: 50
	  end

	  add_index "person_name_code", ["family_name_code"], name: "family_name_code", using: :btree
	  add_index "person_name_code", ["given_name_code", "family_name_code"], name: "given_family_name_code", using: :btree
	  add_index "person_name_code", ["given_name_code"], name: "given_name_code", using: :btree
	  add_index "person_name_code", ["middle_name_code"], name: "middle_name_code", using: :btree
	  add_index "person_name_code", ["person_name_id"], name: "name_for_patient", using: :btree

	  create_table "pharmacy_encounter_type", primary_key: "pharmacy_encounter_type_id", force: true do |t|
	    t.string   "name",          limit: 50,                  null: false
	    t.text     "description",                               null: false
	    t.string   "format",        limit: 50
	    t.integer  "foreign_key"
	    t.boolean  "searchable"
	    t.integer  "creator",                   default: 0,     null: false
	    t.datetime "date_created",                              null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.boolean  "retired",                   default: false, null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason", limit: 225
	  end

	  create_table "pharmacy_obs", primary_key: "pharmacy_module_id", force: true do |t|
	    t.integer  "pharmacy_encounter_type",             default: 0,     null: false
	    t.integer  "drug_id",                             default: 0,     null: false
	    t.float    "value_numeric",           limit: 53
	    t.float    "expiring_units",          limit: 53
	    t.integer  "pack_size"
	    t.integer  "value_coded"
	    t.string   "value_text",              limit: 15
	    t.date     "expiry_date"
	    t.date     "encounter_date",                                      null: false
	    t.integer  "creator",                                             null: false
	    t.datetime "date_created",                                        null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.boolean  "voided",                              default: false, null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason",             limit: 225
	  end

	  create_table "privilege", primary_key: "privilege", force: true do |t|
	    t.string "description", limit: 250, default: "", null: false
	    t.string "uuid",        limit: 38,               null: false
	  end

	  add_index "privilege", ["uuid"], name: "privilege_uuid_index", unique: true, using: :btree

	  create_table "program", primary_key: "program_id", force: true do |t|
	    t.integer  "concept_id",               default: 0, null: false
	    t.integer  "creator",                  default: 0, null: false
	    t.datetime "date_created",                         null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.integer  "retired",      limit: 2,   default: 0, null: false
	    t.string   "name",         limit: 50,              null: false
	    t.string   "description",  limit: 500
	    t.string   "uuid",         limit: 38,              null: false
	  end

	  add_index "program", ["changed_by"], name: "user_who_changed_program", using: :btree
	  add_index "program", ["concept_id"], name: "program_concept", using: :btree
	  add_index "program", ["creator"], name: "program_creator", using: :btree
	  add_index "program", ["uuid"], name: "program_uuid_index", unique: true, using: :btree

	  create_table "program_encounter", primary_key: "program_encounter_id", force: true do |t|
	    t.integer  "patient_id"
	    t.datetime "date_time"
	    t.integer  "program_id"
	  end

	  create_table "program_encounter_details", force: true do |t|
	    t.integer "encounter_id"
	    t.integer "program_encounter_id"
	    t.integer "program_id"
	    t.integer "voided",               default: 0
	  end

	  create_table "program_encounter_type_map", primary_key: "program_encounter_type_map_id", force: true do |t|
	    t.integer "program_id"
	    t.integer "encounter_type_id"
	  end

	  add_index "program_encounter_type_map", ["encounter_type_id"], name: "referenced_encounter_type", using: :btree
	  add_index "program_encounter_type_map", ["program_id", "encounter_type_id"], name: "program_mapping", using: :btree

	  create_table "program_location_restriction", primary_key: "program_location_restriction_id", force: true do |t|
	    t.integer "program_id"
	    t.integer "location_id"
	  end

	  add_index "program_location_restriction", ["location_id"], name: "referenced_location", using: :btree
	  add_index "program_location_restriction", ["program_id", "location_id"], name: "program_mapping", using: :btree

	  create_table "program_orders_map", primary_key: "program_orders_map_id", force: true do |t|
	    t.integer "program_id"
	    t.integer "concept_id"
	  end

	  add_index "program_orders_map", ["concept_id"], name: "referenced_concept_id", using: :btree
	  add_index "program_orders_map", ["program_id", "concept_id"], name: "program_mapping", using: :btree

	  create_table "program_patient_identifier_type_map", primary_key: "program_patient_identifier_type_map_id", force: true do |t|
	    t.integer "program_id"
	    t.integer "patient_identifier_type_id"
	  end

	  add_index "program_patient_identifier_type_map", ["patient_identifier_type_id"], name: "referenced_patient_identifier_type", using: :btree
	  add_index "program_patient_identifier_type_map", ["program_id", "patient_identifier_type_id"], name: "program_mapping", using: :btree

	  create_table "program_relationship_type_map", primary_key: "program_relationship_type_map_id", force: true do |t|
	    t.integer "program_id"
	    t.integer "relationship_type_id"
	  end

	  add_index "program_relationship_type_map", ["program_id", "relationship_type_id"], name: "program_mapping", using: :btree
	  add_index "program_relationship_type_map", ["relationship_type_id"], name: "referenced_relationship_type", using: :btree

	  create_table "program_workflow", primary_key: "program_workflow_id", force: true do |t|
	    t.integer  "program_id",              default: 0, null: false
	    t.integer  "concept_id",              default: 0, null: false
	    t.integer  "creator",                 default: 0, null: false
	    t.datetime "date_created",                        null: false
	    t.integer  "retired",      limit: 2,  default: 0, null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.string   "uuid",         limit: 38,             null: false
	  end

	  add_index "program_workflow", ["changed_by"], name: "workflow_voided_by", using: :btree
	  add_index "program_workflow", ["concept_id"], name: "workflow_concept", using: :btree
	  add_index "program_workflow", ["creator"], name: "workflow_creator", using: :btree
	  add_index "program_workflow", ["program_id"], name: "program_for_workflow", using: :btree
	  add_index "program_workflow", ["uuid"], name: "program_workflow_uuid_index", unique: true, using: :btree

	  create_table "program_workflow_state", primary_key: "program_workflow_state_id", force: true do |t|
	    t.integer  "program_workflow_id",            default: 0, null: false
	    t.integer  "concept_id",                     default: 0, null: false
	    t.integer  "initial",             limit: 2,  default: 0, null: false
	    t.integer  "terminal",            limit: 2,  default: 0, null: false
	    t.integer  "creator",                        default: 0, null: false
	    t.datetime "date_created",                               null: false
	    t.integer  "retired",             limit: 2,  default: 0, null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.string   "uuid",                limit: 38,             null: false
	  end

	  add_index "program_workflow_state", ["changed_by"], name: "state_voided_by", using: :btree
	  add_index "program_workflow_state", ["concept_id"], name: "state_concept", using: :btree
	  add_index "program_workflow_state", ["creator"], name: "state_creator", using: :btree
	  add_index "program_workflow_state", ["program_workflow_id"], name: "workflow_for_state", using: :btree
	  add_index "program_workflow_state", ["uuid"], name: "program_workflow_state_uuid_index", unique: true, using: :btree

	  create_table "regimen", primary_key: "regimen_id", force: true do |t|
	    t.integer  "concept_id",              default: 0,   null: false
	    t.string   "regimen_index", limit: 5
	    t.integer  "min_weight",              default: 0,   null: false
	    t.integer  "max_weight",              default: 200, null: false
	    t.integer  "creator",                 default: 0,   null: false
	    t.datetime "date_created",                          null: false
	    t.integer  "retired",       limit: 2, default: 0,   null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.integer  "program_id",              default: 0,   null: false
	  end

	  add_index "regimen", ["concept_id"], name: "map_concept", using: :btree

	  create_table "regimen_drug_order", primary_key: "regimen_drug_order_id", force: true do |t|
	    t.integer  "regimen_id",                       default: 0,     null: false
	    t.integer  "drug_inventory_id",                default: 0
	    t.float    "dose",                  limit: 53
	    t.float    "equivalent_daily_dose", limit: 53
	    t.string   "units"
	    t.string   "frequency"
	    t.boolean  "prn",                              default: false, null: false
	    t.boolean  "complex",                          default: false, null: false
	    t.integer  "quantity"
	    t.text     "instructions"
	    t.integer  "creator",                          default: 0,     null: false
	    t.datetime "date_created",                                     null: false
	    t.integer  "voided",                limit: 2,  default: 0,     null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	    t.string   "uuid",                  limit: 38,                 null: false
	  end

	  add_index "regimen_drug_order", ["creator"], name: "regimen_drug_order_creator", using: :btree
	  add_index "regimen_drug_order", ["drug_inventory_id"], name: "map_drug_inventory", using: :btree
	  add_index "regimen_drug_order", ["regimen_id"], name: "map_regimen", using: :btree
	  add_index "regimen_drug_order", ["uuid"], name: "regimen_drug_order_uuid_index", unique: true, using: :btree
	  add_index "regimen_drug_order", ["voided_by"], name: "user_who_voided_regimen_drug_order", using: :btree

	  create_table "region", primary_key: "region_id", force: true do |t|
	    t.string   "name",          default: "",    null: false
	    t.integer  "creator",       default: 0,     null: false
	    t.datetime "date_created",                  null: false
	    t.boolean  "retired",       default: false, null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	  end

	  add_index "region", ["creator"], name: "user_who_created_region", using: :btree
	  add_index "region", ["retired"], name: "retired_status", using: :btree
	  add_index "region", ["retired_by"], name: "user_who_retired_region", using: :btree

	  create_table "relationship", primary_key: "relationship_id", force: true do |t|
	    t.integer  "person_a",                            null: false
	    t.integer  "relationship",            default: 0, null: false
	    t.integer  "person_b",                            null: false
	    t.integer  "creator",                 default: 0, null: false
	    t.datetime "date_created",                        null: false
	    t.integer  "voided",       limit: 2,  default: 0, null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	    t.string   "uuid",         limit: 38
	  end

	  add_index "relationship", ["creator"], name: "relation_creator", using: :btree
	  add_index "relationship", ["person_a"], name: "related_person", using: :btree
	  add_index "relationship", ["person_b"], name: "related_relative", using: :btree
	  add_index "relationship", ["relationship"], name: "relationship_type", using: :btree
	  add_index "relationship", ["uuid"], name: "relationship_uuid_index", unique: true, using: :btree
	  add_index "relationship", ["voided_by"], name: "relation_voider", using: :btree

	  create_table "relationship_type", primary_key: "relationship_type_id", force: true do |t|
	    t.string   "a_is_to_b",     limit: 50,                 null: false
	    t.string   "b_is_to_a",     limit: 50,                 null: false
	    t.integer  "preferred",                default: 0,     null: false
	    t.integer  "weight",                   default: 0,     null: false
	    t.string   "description",              default: "",    null: false
	    t.integer  "creator",                  default: 0,     null: false
	    t.datetime "date_created",                             null: false
	    t.string   "uuid",          limit: 38,                 null: false
	    t.boolean  "retired",                  default: false, null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	  end

	  add_index "relationship_type", ["creator"], name: "user_who_created_rel", using: :btree
	  add_index "relationship_type", ["retired_by"], name: "user_who_retired_relationship_type", using: :btree
	  add_index "relationship_type", ["uuid"], name: "relationship_type_uuid_index", unique: true, using: :btree

	  create_table "report_def", primary_key: "report_def_id", force: true do |t|
	    t.text     "name",         limit: 16777215,             null: false
	    t.datetime "date_created",                              null: false
	    t.integer  "creator",                       default: 0, null: false
	  end

	  add_index "report_def", ["creator"], name: "User who created report_def", using: :btree

	  create_table "report_object", primary_key: "report_object_id", force: true do |t|
	    t.string   "name",                                            null: false
	    t.string   "description",            limit: 1000
	    t.string   "report_object_type",                              null: false
	    t.string   "report_object_sub_type",                          null: false
	    t.text     "xml_data"
	    t.integer  "creator",                                         null: false
	    t.datetime "date_created",                                    null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.integer  "voided",                 limit: 2,    default: 0, null: false
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	    t.string   "uuid",                   limit: 38,               null: false
	  end

	  add_index "report_object", ["changed_by"], name: "user_who_changed_report_object", using: :btree
	  add_index "report_object", ["creator"], name: "report_object_creator", using: :btree
	  add_index "report_object", ["uuid"], name: "report_object_uuid_index", unique: true, using: :btree
	  add_index "report_object", ["voided_by"], name: "user_who_voided_report_object", using: :btree

	  create_table "report_schema_xml", primary_key: "report_schema_id", force: true do |t|
	    t.string "name",                         null: false
	    t.text   "description",                  null: false
	    t.text   "xml_data",    limit: 16777215, null: false
	    t.string "uuid",        limit: 38,       null: false
	  end

	  add_index "report_schema_xml", ["uuid"], name: "report_schema_xml_uuid_index", unique: true, using: :btree

	  create_table "reporting_report_design", force: true do |t|
	    t.string   "uuid",                 limit: 38,                   null: false
	    t.string   "name",                                              null: false
	    t.string   "description",          limit: 1000
	    t.integer  "report_definition_id",              default: 0,     null: false
	    t.string   "renderer_type",                                     null: false
	    t.text     "properties"
	    t.integer  "creator",                           default: 0,     null: false
	    t.datetime "date_created",                                      null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.boolean  "retired",                           default: false, null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	  end

	  add_index "reporting_report_design", ["changed_by"], name: "changed_by for reporting_report_design", using: :btree
	  add_index "reporting_report_design", ["creator"], name: "creator for reporting_report_design", using: :btree
	  add_index "reporting_report_design", ["report_definition_id"], name: "report_definition_id for reporting_report_design", using: :btree
	  add_index "reporting_report_design", ["retired_by"], name: "retired_by for reporting_report_design", using: :btree

	  create_table "reporting_report_design_resource", force: true do |t|
	    t.string   "uuid",             limit: 38,                         null: false
	    t.string   "name",                                                null: false
	    t.string   "description",      limit: 1000
	    t.integer  "report_design_id",                    default: 0,     null: false
	    t.string   "content_type",     limit: 50
	    t.string   "extension",        limit: 20
	    t.binary   "contents",         limit: 2147483647
	    t.integer  "creator",                             default: 0,     null: false
	    t.datetime "date_created",                                        null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.boolean  "retired",                             default: false, null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	  end

	  add_index "reporting_report_design_resource", ["changed_by"], name: "changed_by for reporting_report_design_resource", using: :btree
	  add_index "reporting_report_design_resource", ["creator"], name: "creator for reporting_report_design_resource", using: :btree
	  add_index "reporting_report_design_resource", ["report_design_id"], name: "report_design_id for reporting_report_design_resource", using: :btree
	  add_index "reporting_report_design_resource", ["retired_by"], name: "retired_by for reporting_report_design_resource", using: :btree

	  create_table "role", primary_key: "role", force: true do |t|
	    t.string "description",            default: "", null: false
	    t.string "uuid",        limit: 38,              null: false
	  end

	  add_index "role", ["uuid"], name: "role_uuid_index", unique: true, using: :btree

	  create_table "role_privilege", id: false, force: true do |t|
	    t.string "role",      limit: 50, default: "", null: false
	    t.string "privilege", limit: 50, default: "", null: false
	  end

	  add_index "role_privilege", ["role"], name: "role_privilege", using: :btree

	  create_table "role_role", id: false, force: true do |t|
	    t.string "parent_role", limit: 50, default: "", null: false
	    t.string "child_role",             default: "", null: false
	  end

	  add_index "role_role", ["child_role"], name: "inherited_role", using: :btree

	  create_table "scheduler_task_config", primary_key: "task_config_id", force: true do |t|
	    t.string   "name",                                                             null: false
	    t.string   "description",         limit: 1024
	    t.text     "schedulable_class"
	    t.datetime "start_time"
	    t.string   "start_time_pattern",  limit: 50
	    t.integer  "repeat_interval",                  default: 0,                     null: false
	    t.integer  "start_on_startup",                 default: 0,                     null: false
	    t.integer  "started",                          default: 0,                     null: false
	    t.integer  "created_by",                       default: 0
	    t.datetime "date_created",                     default: '2005-01-01 00:00:00'
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.string   "uuid",                limit: 38,                                   null: false
	    t.datetime "last_execution_time"
	  end

	  add_index "scheduler_task_config", ["changed_by"], name: "schedule_changer", using: :btree
	  add_index "scheduler_task_config", ["created_by"], name: "schedule_creator", using: :btree
	  add_index "scheduler_task_config", ["uuid"], name: "scheduler_task_config_uuid_index", unique: true, using: :btree

	  create_table "scheduler_task_config_property", primary_key: "task_config_property_id", force: true do |t|
	    t.string  "name",           null: false
	    t.text    "value"
	    t.integer "task_config_id"
	  end

	  add_index "scheduler_task_config_property", ["task_config_id"], name: "task_config", using: :btree

	  create_table "schema_info", id: false, force: true do |t|
	    t.integer "version"
	  end

	  create_table "serialized_object", primary_key: "serialized_object_id", force: true do |t|
	    t.string   "name",                                         null: false
	    t.string   "description",         limit: 5000
	    t.string   "type",                                         null: false
	    t.string   "subtype",                                      null: false
	    t.string   "serialization_class",                          null: false
	    t.text     "serialized_data",                              null: false
	    t.datetime "date_created",                                 null: false
	    t.integer  "creator",                                      null: false
	    t.datetime "date_changed"
	    t.integer  "changed_by"
	    t.integer  "retired",             limit: 2,    default: 0, null: false
	    t.datetime "date_retired"
	    t.integer  "retired_by"
	    t.string   "retire_reason",       limit: 1000
	    t.string   "uuid",                limit: 38,               null: false
	  end

	  add_index "serialized_object", ["changed_by"], name: "serialized_object_changed_by", using: :btree
	  add_index "serialized_object", ["creator"], name: "serialized_object_creator", using: :btree
	  add_index "serialized_object", ["retired_by"], name: "serialized_object_retired_by", using: :btree
	  add_index "serialized_object", ["uuid"], name: "serialized_object_uuid_index", unique: true, using: :btree

	  create_table "sessions", force: true do |t|
	    t.string   "session_id"
	    t.text     "data"
	    t.datetime "updated_at"
	  end

	  add_index "sessions", ["session_id"], name: "sessions_session_id_index", using: :btree

	  create_table "task", primary_key: "task_id", force: true do |t|
	    t.string   "url"
	    t.string   "encounter_type"
	    t.text     "description"
	    t.string   "location"
	    t.string   "gender",                        limit: 50
	    t.integer  "has_obs_concept_id"
	    t.integer  "has_obs_value_coded"
	    t.integer  "has_obs_value_drug"
	    t.datetime "has_obs_value_datetime"
	    t.float    "has_obs_value_numeric",         limit: 53
	    t.text     "has_obs_value_text"
	    t.integer  "has_program_id"
	    t.integer  "has_program_workflow_state_id"
	    t.integer  "has_identifier_type_id"
	    t.integer  "has_relationship_type_id"
	    t.integer  "has_order_type_id"
	    t.integer  "skip_if_has",                   limit: 2,  default: 0
	    t.float    "sort_weight",                   limit: 53
	    t.integer  "creator",                                              null: false
	    t.datetime "date_created",                                         null: false
	    t.integer  "voided",                        limit: 2,  default: 0
	    t.integer  "voided_by"
	    t.datetime "date_voided"
	    t.string   "void_reason"
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.string   "uuid",                          limit: 38
	  end

	  add_index "task", ["changed_by"], name: "user_who_changed_task", using: :btree
	  add_index "task", ["creator"], name: "task_creator", using: :btree
	  add_index "task", ["voided_by"], name: "user_who_voided_task", using: :btree

	  create_table "traditional_authority", primary_key: "traditional_authority_id", force: true do |t|
	    t.string   "name",          default: "",    null: false
	    t.integer  "district_id",   default: 0,     null: false
	    t.integer  "creator",       default: 0,     null: false
	    t.datetime "date_created",                  null: false
	    t.boolean  "retired",       default: false, null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	  end

	  add_index "traditional_authority", ["creator"], name: "user_who_created_traditional_authority", using: :btree
	  add_index "traditional_authority", ["district_id"], name: "district_for_ta", using: :btree
	  add_index "traditional_authority", ["retired"], name: "retired_status", using: :btree
	  add_index "traditional_authority", ["retired_by"], name: "user_who_retired_traditional_authority", using: :btree

	  create_table "tribe", primary_key: "tribe_id", force: true do |t|
	    t.boolean "retired",            default: false, null: false
	    t.string  "name",    limit: 50, default: "",    null: false
	  end

	  create_table "user_property", id: false, force: true do |t|
	    t.integer "user_id",                    default: 0,  null: false
	    t.string  "property",       limit: 100, default: "", null: false
	    t.string  "property_value", limit: 600, default: "", null: false
	  end

	  create_table "user_role", id: false, force: true do |t|
	    t.integer "user_id",            default: 0,  null: false
	    t.string  "role",    limit: 50, default: "", null: false
	  end

	  add_index "user_role", ["user_id"], name: "user_role", using: :btree

	  create_table "users", primary_key: "user_id", force: true do |t|
	    t.string   "system_id",            limit: 50,  default: "", null: false
	    t.string   "username",             limit: 50
	    t.string   "password",             limit: 128
	    t.string   "salt",                 limit: 128
	    t.string   "secret_question"
	    t.string   "secret_answer"
	    t.integer  "creator",                          default: 0,  null: false
	    t.datetime "date_created",                                  null: false
	    t.integer  "changed_by"
	    t.datetime "date_changed"
	    t.integer  "person_id"
	    t.integer  "retired",              limit: 1,   default: 0,  null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	    t.string   "uuid",                 limit: 38,               null: false
	    t.string   "authentication_token"
	  end

	  add_index "users", ["changed_by"], name: "user_who_changed_user", using: :btree
	  add_index "users", ["creator"], name: "user_creator", using: :btree
	  add_index "users", ["person_id"], name: "person_id_for_user", using: :btree
	  add_index "users", ["retired_by"], name: "user_who_retired_this_user", using: :btree

	  create_table "village", primary_key: "village_id", force: true do |t|
	    t.string   "name",                     default: "",    null: false
	    t.integer  "traditional_authority_id", default: 0,     null: false
	    t.integer  "creator",                  default: 0,     null: false
	    t.datetime "date_created",                             null: false
	    t.boolean  "retired",                  default: false, null: false
	    t.integer  "retired_by"
	    t.datetime "date_retired"
	    t.string   "retire_reason"
	  end

	  add_index "village", ["creator"], name: "user_who_created_village", using: :btree
	  add_index "village", ["retired"], name: "retired_status", using: :btree
	  add_index "village", ["retired_by"], name: "user_who_retired_village", using: :btree
	  add_index "village", ["traditional_authority_id"], name: "ta_for_village", using: :btree

	  create_table "weight_for_height", id: false, force: true do |t|
	    t.float   "supinecm",   limit: 53
	    t.float   "medianwtht", limit: 53
	    t.float   "sdlowwtht",  limit: 53
	    t.float   "sdhighwtht", limit: 53
	    t.integer "sex",        limit: 2
	    t.string  "heightsex",  limit: 5
	  end

	  create_table "weight_for_heights", force: true do |t|
	    t.float   "supine_cm",                   limit: 24
	    t.float   "median_weight_height",        limit: 24
	    t.float   "standard_low_weight_height",  limit: 24
	    t.float   "standard_high_weight_height", limit: 24
	    t.integer "sex"
	  end

	  create_table "weight_height_for_age", id: false, force: true do |t|
	    t.integer "agemths",  limit: 2
	    t.integer "sex",      limit: 2
	    t.float   "medianht", limit: 53
	    t.float   "sdlowht",  limit: 53
	    t.float   "sdhighht", limit: 53
	    t.float   "medianwt", limit: 53
	    t.float   "sdlowwt",  limit: 53
	    t.float   "sdhighwt", limit: 53
	    t.string  "agesex",   limit: 4
	  end

	  create_table "weight_height_for_ages", id: false, force: true do |t|
	    t.integer "age_in_months",        limit: 2
	    t.string  "sex",                  limit: 12
	    t.float   "median_height",        limit: 53
	    t.float   "standard_low_height",  limit: 53
	    t.float   "standard_high_height", limit: 53
	    t.float   "median_weight",        limit: 53
	    t.float   "standard_low_weight",  limit: 53
	    t.float   "standard_high_weight", limit: 53
	    t.string  "age_sex",              limit: 4
	  end

	  add_index "weight_height_for_ages", ["age_in_months"], name: "index_weight_height_for_ages_on_age_in_months", using: :btree
	  add_index "weight_height_for_ages", ["sex"], name: "index_weight_height_for_ages_on_sex", using: :btree

	end
  end

  desc "ht seed"
  
  task seed: :environment do
  	db_user = YAML::load_file('config/database.yml')[Rails.env]['username']
  	db_password = YAML::load_file('config/database.yml')[Rails.env]['password']
  	db_database = YAML::load_file('config/database.yml')[Rails.env]['database']

  	system "mysql -u #{db_user} -p#{db_password} #{db_database} < db/openmrs_metadata_1_7.sql"
  end

end
