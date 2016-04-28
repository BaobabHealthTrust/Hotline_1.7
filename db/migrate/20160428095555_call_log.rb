class CallLog < ActiveRecord::Migration
  def change
 		create_table :call_log, :id => false do |t|
		  t.integer  :call_log_id	 
		  t.datetime :start_time
		  t.datetime :end_time
		  t.string   :call_type
		  t.integer  :creator,     null: false
		  t.string   :district,    null: false
		  t.integer  :call_mode,   null: false
		  t.timestamps

			t.primary_key :call_log_id
  	end 
  end
end
