class Mapping < ActiveRecord::Base

  # Named Scopes
  scope :current, -> { all }

  # Model Validation
  validates_presence_of :source_id, :variable_id, :table, :column

  # Model Relationships

  belongs_to :source
  belongs_to :variable

  # Mapping Methods

  # Provides the human table name
  # Tables can be named to specify a timepoint
  def human_table
    self.source.table_hash[self.table].blank? ? self.table : self.source.table_hash[self.table]
  end

  def mapped?(current_user)
    if self.variable.variable_type == 'choices'
      (self.column_values(current_user).reject{|v| v == nil}.collect{|v| v.to_s} | self.variable.domain_values).size <= self.variable.domain_values.size
    else
      true
    end
  end

  # Returns unique column values in alphabetical order
  def column_values(current_user)
    Aqueduct::Builder.wrapper(self.source, current_user).column_values(self.table, self.column)[:result].sort{|a,b| a.to_s <=> b.to_s}
  end

  def all_values_for_column(current_user)
    if self.source.user_has_action?(current_user, "edit data source mappings") or self.source.user_has_action?(current_user, "view data distribution") or (self.variable and self.variable.sensitivity == '0' and self.source.user_has_action?(current_user, "view limited data distribution"))
      Aqueduct::Builder.wrapper(self.source, current_user).get_all_values_for_column(self.table, self.column)
    else
      { values: [], error: "User does not have appropriate permissions." }
    end
  end

  def abstract_value(criterium)
    result = []
    criterium_value = criterium.value

    return ['1 = 1'] if criterium_value.blank?

    case self.variable.variable_type when 'date', 'integer', 'numeric'
      result = criterium_value.to_s.gsub(/[^0-9\.\,><=\[\]\(\)\:]/, '').split(',')
    when 'choices'
      if criterium.negated?
        full_set = self.variable.domain.options.collect{|option| option[:value]}
        criterium_value = (full_set - criterium_value.split(',')).join(',')
      end
      result = criterium_value.to_s.split(',').collect{|v| "'" + v.to_s.gsub(/[^\w\-\.]/, '') + "'" }
    else
      return ['1 = 0']
    end

    result
  end

  # Returns the display name of the corresponding variable domain choice if the variable type is choices
  # And the value itself if an appropriate match can not be found
  def human_normalized_value(val)
    if self.variable.variable_type == 'choices'
      self.variable.domain.options.select{|option| option[:value].to_s == val.to_s}.collect{|option| option[:display_name]}.first || 'Unknown'
    else
      val
    end
  end

  def graph_values_short(current_user)
    values = self.all_values_for_column(current_user)[:values]

    case self.variable.variable_type when 'integer'
      values = values.select{|v| not v.blank?}.collect{|num_string| num_string.to_i} # Ignore null and blank values!
    when 'numeric'
      values = values.select{|v| not v.blank?}.collect{|num_string| num_string.to_f} # Ignore null and blank values!
    when 'choices'
      values = values.sort{|a,b|( a and b ) ? a <=> b : ( a ? -1 : 1 ) }.group_by{|val| val}.collect do |key, array|
        { name: "#{self.human_normalized_value(key)} in #{self.source.name} at #{self.human_table}", y: array.size, id: key.to_s, mapping_id: self.id }
      end
    end

    values
  end

  def graph_values(current_user)
    categories = []
    values = self.all_values_for_column(current_user)[:values]

    case self.variable.variable_type when 'numeric', 'integer'
      values = values.select{|v| not v.blank?}.collect{|num_string| num_string.to_i} # Ignore null and blank values!
      min = values.min || 0 # (values.min > 0) ? values.min : 0
      max = values.max || 0
      my_array = Array.new((max + 1)-min, 0)
      tmp_categories = Array.new((max + 1)-min, 0)
      num_zeros = 0
      prior_zero_detected = true
      (min..max).each do |inc|
        # Print value if it's the first or last occurence in a sequence of zero record, or if there are records with that value
        if values.count(inc) > 0 or not prior_zero_detected or values.count(inc+1) > 0
          my_array[inc-min-num_zeros] = values.count(inc)
          tmp_categories[inc-min-num_zeros] = inc.to_s
          prior_zero_detected = (values.count(inc) == 0)
        else
          num_zeros += 1
        end
      end
      top_value = ((max)-min-num_zeros)
      values = my_array[0..top_value]
      categories = tmp_categories[0..top_value]
    when 'choices'
      values = values.sort{|a,b|( a and b ) ? a <=> b : ( a ? -1 : 1 ) }.group_by{|val| val}.collect do |key, array|
        { name: "#{self.human_normalized_value(key)} in #{self.source.name} at #{self.human_table}", y: array.size, id: key.to_s, mapping_id: self.id }
      end
    end

    values = { "#{self.source.name}.#{self.column}" => values }

    { values: values, categories: categories }
  end

  # Returns whether the user can see the mapping given a set of valid source rules
  def user_can_view?(current_user, actions_required)
    sensitive_variable = (self.variable.sensitivity != '0')
    return true if actions_required.include?('download files') and self.source.user_has_action?(current_user, 'download files')
    return true if actions_required.include?('download dataset') and self.source.user_has_action?(current_user, 'download dataset')
    return true if actions_required.include?('view data distribution') and self.source.user_has_action?(current_user, 'view data distribution')

    return true if actions_required.include?('download limited dataset') and self.source.user_has_action?(current_user, 'download limited dataset') and not sensitive_variable
    return true if actions_required.include?('view limited data distribution') and self.source.user_has_action?(current_user, 'view limited data distribution') and not sensitive_variable

    return false
  end

end
