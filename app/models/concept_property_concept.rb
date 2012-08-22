class ConceptPropertyConcept < ActiveRecord::Base
  belongs_to :concept_one, class_name: 'Concept', foreign_key: 'concept_one_id'
  belongs_to :concept_two, class_name: 'Concept', foreign_key: 'concept_two_id'
end
