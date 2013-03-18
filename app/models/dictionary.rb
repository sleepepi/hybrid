class Dictionary < ActiveRecord::Base

  STATUS = ["active", "testing", "inactive"].collect{|i| [i,i]}

  # Concerns
  include Deletable

  # Named Scopes
  scope :available, -> { where deleted: false, visible: true }
  scope :search, lambda { |arg| where('LOWER(name) LIKE ?', arg.to_s.downcase.gsub(/^| |$/, '%')) }

  # Model Validation
  validates_presence_of :name
  validates_uniqueness_of :name

  # Model Relationships
  belongs_to :user

  has_many :concepts #, conditions: { deleted: false }
  has_many :concept_property_concepts, through: :concepts

  # Methods

  # This function is run after an dictionary is imported or destroyed.
  # Removes all concepts in the dictionary that aren't the same version as well as cleaning up any terms that are no longer associated with any concept.
  def cleanup(version)
    Concept.destroy_all(['dictionary_id = ? and (version != ? or version IS NULL)', self.id, version])

    # Term.all.select{|t| t.concepts.size == 0}.collect{|term| term.destroy}
  end

  def export_csv
    csv_string = CSV.generate do |csv|
      # header row
      csv << ["#URI", "Namespace", "Short Name", "Description", "Concept Type", "Units", "Terms", "Internal Terms", "Parents", "Children", "Field Values", "Sensitivity", "Display Name", "Commonly Used", "Folder", "Calculation", "Source Name", "Source File", "Source Description"]

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
        c = Concept.where( name: concept_name, uri: line[0], namespace: line[1], short_name: line[2]).first_or_create
        c.dictionary_id = self.id
        c.version = dictionary_version
        c.description = line[3]
        c.concept_type = line[4]
        c.units = line[5]

        c.sensitivity = Concept::SENSITIVITY.collect{|s| s[1]}.include?(line[11]) ? line[11] : '0'
        c.display_name = line[12]
        c.commonly_used = (line[13] == '1')
        c.folder = line[14]
        c.formula = line[15]
        c.source_name = line[16]
        c.source_file = line[17]
        c.source_description = line[18]
        c.save

        c.terms.destroy_all
        line[6].to_s.split(';').each do |label|
          term = c.terms.where( name: label.strip, internal: false ).first_or_create
          term.update_search_name!
        end

        line[7].to_s.split(';').each do |internal_label|
          internal_term = c.terms.where( name: internal_label.strip, internal: true ).first_or_create
          internal_term.update_search_name!
        end

        line[8].to_s.split(';').each do |parent_name|
          (parent_name, parent_uri, parent_namespace, parent_short_name) = Concept.name_to_uri_and_namespace_and_short_name(parent_name.strip, c.uri, c.namespace)
          concept_parent = Concept.where(name: parent_name, uri: parent_uri, namespace: parent_namespace, short_name: parent_short_name).first_or_create
          concept_parent.update_column :version, dictionary_version
          concept_parent.update_column :dictionary_id, self.id if concept_parent.dictionary_id.blank?
          concept_parent.update_status!
          cpc = ConceptPropertyConcept.where( concept_one_id: c.id, concept_two_id: concept_parent.id ).first_or_create
        end

        line[9].to_s.split(';').each do |child_name|
          (child_name, child_uri, child_namespace, child_short_name) = Concept.name_to_uri_and_namespace_and_short_name(child_name.strip, c.uri, c.namespace)
          concept_child = Concept.where(name: child_name.strip, uri: child_uri, namespace: child_namespace, short_name: child_short_name).first_or_create
          concept_child.update_column :version, dictionary_version
          concept_child.update_column :dictionary_id, self.id if concept_child.dictionary_id.blank?
          if c.categorical?
            concept_child.update_column :concept_type, 'boolean'
          elsif not c.concept_type.blank?
            concept_child.update_column :concept_type, c.concept_type
          end
          concept_child.update_status!
          cpc = ConceptPropertyConcept.where( concept_one_id: concept_child.id, concept_two_id: c.id ).first_or_create
        end

        # Field values for categoricals may be referencing children in line[11]
        line[10].to_s.split(';').each_with_index do |field_value, i|
          if c.categorical? and not line[9].to_s.split(';')[i].blank?
            child_name = line[9].to_s.split(';')[i]
            (child_name, child_uri, child_namespace, child_short_name) = Concept.name_to_uri_and_namespace_and_short_name(child_name.strip, c.uri, c.namespace)
            concept_child = Concept.find_by_name_and_uri_and_namespace_and_short_name(child_name.strip, child_uri, child_namespace, child_short_name)
            internal_term = concept_child.terms.where( name: field_value.strip, internal: true ).first_or_create
            internal_term.update_search_name!
          end
        end

        c.update_unit_type!
        c.update_status!
      end
    end

    self.cleanup(dictionary_version)
  end

end
