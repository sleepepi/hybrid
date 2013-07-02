class Dictionary < ActiveRecord::Base

  # Concerns
  include Searchable, Deletable

  # Named Scopes
  scope :available, -> { where deleted: false, visible: true }

  # Model Validation
  validates_presence_of :name
  validates_uniqueness_of :name

  # Model Relationships
  belongs_to :user

  has_many :domains
  has_many :variables

  # Methods

  def clean
    self.domains.destroy_all
    self.variables.destroy_all
  end

  def import_variables(file_name)
    version = Time.now.to_i.to_s

    CSV.parse( File.open(file_name, 'r:iso-8859-1:utf-8'){|f| f.read}, headers: true ) do |line|
      row = line.to_hash

      variable_hash = {}
      [[:folder, 'folder'], [:name, 'id'], [:display_name, 'display_name'], [:description, 'description'], [:units, 'units'], [:calculation, 'calculation']].each do |key, column_name|
        variable_hash[key] = row[column_name].to_s.strip
      end

      domain = self.domains.where( name: row['domain'].to_s.strip ).first

      variable_hash[:domain_id] = domain.id if domain
      variable_hash[:variable_type] = row['type'].to_s.strip if Variable::TYPE.collect{|t| t[1]}.include?(row['type'].to_s.strip)
      variable_hash[:version] = version

      if not variable_hash[:name].blank? and v = self.variables.where( name: variable_hash[:name] ).first
        variable_hash.delete(:name)
        v.update( variable_hash )
      else
        v = self.variables.create( variable_hash )
      end

      if v.valid?
        v.tags = []
        row['labels'].to_s.split(';').each do |tag_name|
          v.tags.create( name: tag_name.to_s.strip ) unless tag_name.to_s.strip.blank?
        end
      end

    end

    self.variables.where( 'version != ? or version IS NULL', version ).destroy_all
  end

  def import_domains(file_name)
    version = Time.now.to_i.to_s
    self.domains.destroy_all

    CSV.parse( File.open(file_name, 'r:iso-8859-1:utf-8'){|f| f.read}, headers: true ) do |line|
      row = line.to_hash

      d = self.domains.where( name: row['domain_id'].to_s.strip ).first_or_create( folder: row['folder'], version: version )

      if d.valid?
        d.options << { value: row['value'].to_s.strip, display_name: row['display_name'].to_s.strip }
        d.save
      end
    end
    self.reload
  end

end
