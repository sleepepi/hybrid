class Dictionary < ActiveRecord::Base
  attr_accessible :name, :description, :visible, :status

  STATUS = ["active", "testing", "inactive"].collect{|i| [i,i]}

  # Named Scopes
  scope :current, conditions: { deleted: false }
  scope :available, conditions: { deleted: false, visible: true }
  scope :search, lambda { |*args| {conditions: [ 'LOWER(name) LIKE ?', '%' + args.first.downcase.split(' ').join('%') + '%' ] } }

  # Model Validation
  validates_presence_of :name
  validates_uniqueness_of :name

  # Model Relationships
  belongs_to :user

  has_many :concepts #, conditions: { deleted: false }
  has_many :concept_property_concepts, through: :concepts

  # Methods

  def destroy
    update_column :deleted, true
  end

  # This function is run after an dictionary is imported or destroyed.
  # Removes all concepts in the dictionary that aren't the same version as well as cleaning up any terms that are no longer associated with any concept.
  def cleanup(version)
    Concept.destroy_all(['dictionary_id = ? and (version != ? or version IS NULL)', self.id, version])

    # Term.all.select{|t| t.concepts.size == 0}.collect{|term| term.destroy}
  end

  def export_csv
    csv_string = CSV.generate do |csv|
      # header row
      csv << ["#URI", "Namespace", "Short Name", "Description", "Concept Type", "Units", "Terms", "Internal Terms", "Parents", "Children", "Equivalent Concepts", "Similar Concepts", "Field Values", "Sensitivity", "Display Name", "Commonly Used", "Folder", "Calculation", "Source Name", "Source File", "Source Description"]

      # data rows
      self.concepts.each do |c|
        if c.uri.blank? or c.namespace.blank? or c.short_name.blank?
          (c.name, c.uri, c.namespace, c.short_name) = Concept.name_to_uri_and_namespace_and_short_name(c.name, SITE_URL)
        end

        field_values = []

        if c.categorical?
          c.children.each do |child|
            field_values << child.internal_terms.first.name if child.internal_terms.first
          end
        end

        csv << [c.uri,
                c.namespace,
                c.short_name,
                c.description,
                c.concept_type,
                c.units,
                c.external_terms.collect{|t| t.name}.join('; '),
                c.internal_terms.collect{|t| t.name}.join('; '),
                c.parents.collect{|t| (t.uri == c.uri and t.namespace == c.namespace) ? "##{t.short_name}" : t.name}.join('; '),
                c.children.collect{|t| (t.uri == c.uri and t.namespace == c.namespace) ? "##{t.short_name}" : t.name}.join('; '),
                c.equivalent_concepts.collect{|t| (t.uri == c.uri and t.namespace == c.namespace) ? "##{t.short_name}" : t.name}.join('; '),
                c.similar_concepts.collect{|t| (t.uri == c.uri and t.namespace == c.namespace) ? "##{t.short_name}" : t.name}.join('; '),
                field_values.join('; '),
                c.sensitivity,
                c.display_name,
                (c.commonly_used? ? '1' : '0'),
                c.folder,
                c.formula,
                c.source_name,
                c.source_file,
                c.source_description ]
      end
    end
    csv_string
  end

  def import_csv(file_name)
    dictionary_version = Time.now.to_i.to_s

    CSV.foreach(file_name) do |line|
      if not line[0].blank? and line[0].first != '#'
        concept_name = line[0] + '/' + line[1] + '#' + line[2]
        c = Concept.find_or_create_by_name_and_uri_and_namespace_and_short_name(concept_name, line[0], line[1], line[2])
        c.dictionary_id = self.id
        c.version = dictionary_version
        c.description = line[3]
        c.concept_type = line[4]
        c.units = line[5]

        c.sensitivity = Concept::SENSITIVITY.collect{|s| s[1]}.include?(line[13]) ? line[13] : '0'
        c.display_name = line[14]
        c.commonly_used = (line[15] == '1')
        c.folder = line[16]
        c.formula = line[17]
        c.source_name = line[18]
        c.source_file = line[19]
        c.source_description = line[20]
        c.save

        c.terms.destroy_all
        line[6].to_s.split(';').each do |label|
          term = c.terms.find_or_create_by_name_and_internal(label.strip, false)
          term.update_search_name!
        end

        line[7].to_s.split(';').each do |internal_label|
          internal_term = c.terms.find_or_create_by_name_and_internal(internal_label.strip, true)
          internal_term.update_search_name!
        end

        line[8].to_s.split(';').each do |parent_name|
          (parent_name, parent_uri, parent_namespace, parent_short_name) = Concept.name_to_uri_and_namespace_and_short_name(parent_name.strip, c.uri, c.namespace)
          concept_parent = Concept.find_or_create_by_name_and_uri_and_namespace_and_short_name(parent_name, parent_uri, parent_namespace, parent_short_name)
          concept_parent.update_column :version, dictionary_version
          concept_parent.update_column :dictionary_id, self.id if concept_parent.dictionary_id.blank?
          concept_parent.update_status!
          cpc = ConceptPropertyConcept.find_or_create_by_concept_one_id_and_concept_two_id_and_property(c.id, concept_parent.id, "is_a")
        end

        line[9].to_s.split(';').each do |child_name|
          (child_name, child_uri, child_namespace, child_short_name) = Concept.name_to_uri_and_namespace_and_short_name(child_name.strip, c.uri, c.namespace)
          concept_child = Concept.find_or_create_by_name_and_uri_and_namespace_and_short_name(child_name.strip, child_uri, child_namespace, child_short_name)
          concept_child.update_column :version, dictionary_version
          concept_child.update_column :dictionary_id, self.id if concept_child.dictionary_id.blank?
          if c.categorical?
            concept_child.update_column :concept_type, 'boolean'
          elsif not c.concept_type.blank?
            concept_child.update_column :concept_type, c.concept_type
          end
          concept_child.update_status!
          cpc = ConceptPropertyConcept.find_or_create_by_concept_one_id_and_concept_two_id_and_property(concept_child.id, c.id, "is_a")
        end

        [['equivalent_class', 10], ['similar_class', 11]].each do |property, position|
          line[position].to_s.split(';').each do |relation_name|
            (relation_name, relation_uri, relation_namespace, relation_short_name) = Concept.name_to_uri_and_namespace_and_short_name(relation_name.strip, c.uri, c.namespace)
            relation_concept = Concept.find_or_create_by_name_and_uri_and_namespace_and_short_name(relation_name.strip, relation_uri, relation_namespace, relation_short_name)
            relation_concept.update_column :version, dictionary_version
            relation_concept.update_column :dictionary_id, self.id if relation_concept.dictionary_id.blank?
            relation_concept.update_status!
            cpc = ConceptPropertyConcept.find_by_concept_one_id_and_concept_two_id_and_property(c.id, relation_concept.id, property)
            cpc = ConceptPropertyConcept.find_or_create_by_concept_one_id_and_concept_two_id_and_property(relation_concept.id, c.id, property) unless cpc
          end
        end

        # Field values for categoricals may be referencing children in line[11]
        line[12].to_s.split(';').each_with_index do |field_value, i|
          if c.categorical? and not line[9].to_s.split(';')[i].blank?
            child_name = line[9].to_s.split(';')[i]
            (child_name, child_uri, child_namespace, child_short_name) = Concept.name_to_uri_and_namespace_and_short_name(child_name.strip, c.uri, c.namespace)
            concept_child = Concept.find_by_name_and_uri_and_namespace_and_short_name(child_name.strip, child_uri, child_namespace, child_short_name)
            internal_term = concept_child.terms.find_or_create_by_name_and_internal(field_value.strip, true)
            internal_term.update_search_name!
          end
        end

        c.update_unit_type!
        c.update_status!
      end
    end

    self.cleanup(dictionary_version)
  end


  # Methods for Parsing OWL Documents
  private

  def second_pass_continuous_concepts
    # puts "Propagating Continuous and DateTime Concepts Downstream"
    self.concepts.where('concept_type IN (?)', ['continuous', 'datetime']).each do |concept|
      push_info_to_children(concept)
    end
  end

  def second_pass_categorical_concepts #(file_name)
  #   self.concepts.where(concept_type: nil).each do |concept|
  #     concept.update_column :concept_type, 'categorical' if concept.children.size > 0
  #   end
  end

  def second_pass_boolean_concepts(file_name)
    self.concepts.where(concept_type: nil).update_all(concept_type: 'boolean')
  end

  def push_info_to_children(concept)
    # If child is already defined stop, else, apply properties and recurse
    concept.children.each do |child|
      if child.concept_type.blank?
        # puts "Child[#{child.qname}] inheriting properties from Parent[#{concept.qname}]"
        child.update_attributes(concept_type: concept.concept_type, units: concept.units, unit_type: concept.unit_type, data_type: concept.data_type)
        push_info_to_children(child)
      end
    end
  end

  def print_difference(difference, item)
    if difference < 0
      # puts "The number of #{item.pluralize} increased by #{pluralize(-1*difference, item)}."
    elsif difference > 0
      # puts "The number of #{item.pluralize} decreased by #{pluralize(difference, item)}."
    else
      # puts "The number of #{item.pluralize} stayed the same."
    end
  end

  def status_update_for_all_concepts
    # puts "Updating Status For All Concepts"
    self.reload
    self.concepts.each do |concept|
      concept.update_status!
    end
  end

  def search_name_update_for_all_terms
    # puts "Updating Search Name For All Terms"
    Term.all.each do |term|
      term.update_search_name!
    end
  end

  def xml_escape(input)
    return '' if input.blank?
    input.gsub!(/[&<>'"]/) do | match |
      {'&' => '&amp;', '<' => '&lt;', '>' => '&gt;', "'" => '&apos;', '"' => '&quot;'}[match]
    end
    return input
  end

end
