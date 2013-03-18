class RemovePropertyFromConceptPropertyConcepts < ActiveRecord::Migration
  def up
    remove_column :concept_property_concepts, :property
  end

  def down
    add_column :concept_property_concepts, :property, :string
  end
end
