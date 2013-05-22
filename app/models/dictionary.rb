class Dictionary < ActiveRecord::Base

  STATUS = ["active", "testing", "inactive"].collect{|i| [i,i]}

  # Concerns
  include Searchable, Deletable

  # Named Scopes
  scope :available, -> { where deleted: false, visible: true }

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
      csv << ["Folder", "Short Name", "Description", "Concept Type", "Units", "Terms", "Internal Terms", "Parents", "Children", "Field Values", "Sensitivity", "Display Name", "Commonly Used", "Calculation", "Source Name", "Source File", "Source Description"]

      # data rows
      self.concepts.each do |c|
        field_values = []

        if c.categorical?
          c.children.each do |child|
            field_values << child.internal_terms.first.name if child.internal_terms.first
          end
        end

        csv << [c.folder,
                c.short_name,
                c.description,
                c.concept_type,
                c.units,
                c.external_terms.collect{|t| t.name}.join('; '),
                c.internal_terms.collect{|t| t.name}.join('; '),
                c.parents.collect{|c| c.short_name }.join('; '),
                c.children.collect{|c| c.short_name }.join('; '),
                field_values.join('; '),
                c.sensitivity,
                c.display_name,
                (c.commonly_used? ? '1' : '0'),
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

    CSV.parse( File.open(file_name, 'r:iso-8859-1:utf-8'){|f| f.read}, headers: true ) do |line|
      row = line.to_hash

      unless row['Short Name'].blank?
        c = self.concepts.where( short_name: row['Short Name'] ).first_or_create
        c.dictionary_id = self.id
        c.version = dictionary_version
        c.description = row['Description']
        c.concept_type = row['Concept Type']
        c.units = row['Units']

        c.sensitivity = Concept::SENSITIVITY.collect{|s| s[1]}.include?(line[9]) ? line[9] : '0'
        c.display_name = row['Display Name']
        c.commonly_used = (row['Commonly Used'] == '1')
        c.folder = row['Folder']
        c.formula = row['Calculation']
        c.source_name = row['Source Name']
        c.source_file = row['Source File']
        c.source_description = row['Source Description']
        c.save

        c.terms.destroy_all
        row['Terms'].to_s.split(';').each do |label|
          term = c.terms.where( name: label.strip, internal: false ).first_or_create
          term.update_search_name!
        end

        row['Internal Terms'].to_s.split(';').each do |internal_label|
          internal_term = c.terms.where( name: internal_label.strip, internal: true ).first_or_create
          internal_term.update_search_name!
        end

        row['Parents'].to_s.split(';').each do |parent_name|
          concept_parent = self.concepts.where( short_name: parent_name.strip ).first_or_create

          unless concept_parent.new_record?
            concept_parent.update_column :version, dictionary_version
            concept_parent.update_column :dictionary_id, self.id if concept_parent.dictionary_id.blank?
            cpc = ConceptPropertyConcept.where( concept_one_id: c.id, concept_two_id: concept_parent.id ).first_or_create
          end
        end

        row['Children'].to_s.split(';').each do |child_name|
          concept_child = self.concepts.where( short_name: child_name.strip ).first_or_create

          unless concept_child.new_record?
            concept_child.update_column :version, dictionary_version
            concept_child.update_column :dictionary_id, self.id if concept_child.dictionary_id.blank?
            if c.categorical?
              concept_child.update_column :concept_type, 'boolean'
            elsif not c.concept_type.blank?
              concept_child.update_column :concept_type, c.concept_type
            end
            cpc = ConceptPropertyConcept.where( concept_one_id: concept_child.id, concept_two_id: c.id ).first_or_create
          end
        end

        # Field values for categoricals may be referencing children in line[11]
        row['Field Values'].to_s.split(';').each_with_index do |field_value, i|
          if c.categorical? and not row['Children'].to_s.split(';')[i].blank?
            child_name = row['Children'].to_s.split(';')[i]
            concept_child = self.concepts.where( short_name: child_name.strip ).first
            if concept_child
              internal_term = concept_child.terms.where( name: field_value.strip, internal: true ).first_or_create
              internal_term.update_search_name!
            end
          end
        end

        c.update_search_name!
      end
    end

    self.cleanup(dictionary_version)
  end

end
