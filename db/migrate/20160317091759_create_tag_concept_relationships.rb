class CreateTagConceptRelationships < ActiveRecord::Migration
  def change
    create_table :tag_concept_relationships do |t|
      t.integer :concept_id, :null => false
      t.integer :tag_id, :null => false
      
      t.timestamps
    end
  end


end
