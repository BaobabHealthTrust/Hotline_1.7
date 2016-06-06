class CallLogUpdate < ActiveRecord::Migration
  def change
	 	create_table :call_log_update, :id => false do |t|
		  t.integer :call_id
		  t.integer :creator
    end
  end
end
