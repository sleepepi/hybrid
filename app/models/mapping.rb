class Mapping < ActiveRecord::Base
  # Named Scopes

  scope :current, -> { where deleted: false }
  scope :status, lambda { |arg| where(status: arg) }

  # Model Validation

  # Model Relationships

  belongs_to :source
  belongs_to :concept

  # Mapping Methods

  def mapped?
    return self.status == 'mapped'
  end

  def set_status!(current_user)
    if self.concept
      if self.concept.continuous?
        if self.units.blank?
          update_column :status, 'unmapped'
        else
          update_column :status, 'mapped'
        end
      elsif self.concept.categorical? or self.concept.boolean?
        self.column_values(current_user).each do |column_value|
          val_mapping = self.source.mappings.find_by_table_and_column_and_column_value(self.table, self.column, (column_value == nil) ? 'NULL' : column_value.to_s)
          if val_mapping and val_mapping.status == 'mapped'
            update_column :status, 'mapped'
            return
          end
        end
        update_column :status, 'unmapped'
      elsif self.concept.date? or self.concept.identifier? or self.concept.file_locator? or self.concept.free_text?
        update_column :status, 'mapped'
      else
        update_column :status, 'unmapped'
      end
    elsif self.concept_id != nil
      update_column :status, 'outdated' # If the concept no longer exists than the mapping has become outdated
    else
      update_column :status, 'unmapped'
    end
  end

  # This function retrieves all of the concepts associated with the table.column mapping
  def all_concepts
    result = []
    result << self.concept if self.concept
    self.source.mappings.where(table: self.table, column: self.column).each do |mapping|
      result << mapping.concept if mapping.concept
    end
    result.uniq!
    result
  end

  # Returns unique column values in alphabetical order
  def column_values(current_user)
    result = []

    result_hash = Aqueduct::Builder.wrapper(self.source, current_user).column_values(self.table, self.column)
    result = result_hash[:result]
    error = result_hash[:error]

    result.sort{|a,b| a.to_s <=> b.to_s}
  end

  def all_values_for_column(current_user)
    if self.source.user_has_action?(current_user, "edit data source mappings") or self.source.user_has_action?(current_user, "view data distribution") or (self.concept and self.concept.sensitivity == '0' and self.source.user_has_action?(current_user, "view limited data distribution"))
      Aqueduct::Builder.wrapper(self.source, current_user).get_all_values_for_column(self.table, self.column)
    else
      { values: [], error: "User does not have appropriate permissions." }
    end
  end

  def column_statistics_given_values(values)
    result = ""
    if values.size > 0
      if self.concept.continuous? # or self.concept.date?
        orig_size = values.size
        values = values.compact.collect{|num_string| num_string.to_f}
        missing_values = orig_size - values.size
        result = '<table class="blank">'
        result += "<tr><td>count</td><td style='text-align:right'>&nbsp;&nbsp;#{values.size}</td></tr>"
        result += "<tr><td>minimum</td><td style='text-align:right'>&nbsp;&nbsp;#{"%0.2f" % (values.min)}</td></tr>"
        result += "<tr><td>maximum</td><td style='text-align:right'>&nbsp;&nbsp;#{"%0.2f" % (values.max)}</td></tr>"
        result += "<tr><td>mean</td><td style='text-align:right'>&nbsp;&nbsp;#{"%0.2f" % (values.sum / values.size)}</td></tr>"
        result += "<tr><td>standard deviation</td><td style='text-align:right'>&nbsp;&nbsp;#{"%0.2f" % (std_dev(values))}</td></tr>"
        result += "<tr><td>missing</td><td style='text-align:right'>&nbsp;&nbsp;#{missing_values}</td></tr>"
        result += '</table>'
      elsif self.concept.categorical? or self.concept.boolean?
        result = '<table class="blank" style="width:100%"><thead><tr><th style="text-align:center">Original Value</th><th style="text-align:center">Mapping</th><th style="text-align:center">Count</th><th style="text-align:right">%</th></tr></thead>'
        values.sort{|a,b|( a and b ) ? a <=> b : ( a ? -1 : 1 ) }.group_by{|val| val}.each do |key, array|
          orig_key = key
          key = '&lt;![CDATA[]]&gt;' if key == ''
          result += "<tr><td style='padding:0 30px'>#{(key == nil ? "NULL" : key.to_s.gsub('&lt;![CDATA[', '"').gsub(']]&gt;', '"').gsub(' ', '&nbsp;')) + '</td><td style="text-align:right;padding:0 30px">' + self.human_normalized_value(orig_key).to_s}</td><td style='text-align:right;padding:0 30px'>#{array.size}</td><td style='text-align:right;padding-left:30px'>#{"%0.2f%" % (array.size * 100.0 / values.size)}</td></tr>"
        end
        result += '</table>'
      else
        result += ' Concept Type Not Supported for Statistics'
      end
    else
      result += 'No Values In Database'
    end
    result

  end

  def generate_derived!
    self.all_concepts.each do |concept|
      # Currently only derive continuous concepts
      if concept.continuous?
        # concept.ancestors_and_self(['boolean', 'continuous', 'datetime', 'categorical']).each do |ancestor|
        concept.ancestors_and_self(['continuous']).each do |ancestor|

          # Create if the concept isn't already mapped in the database to that particular table and column
          # Ex: Mappings for Weight at Baseline and Weight at Followup may exist as two separate columns,
          #     however generic "Weight" would still need to exist as a derived concept for EACH of the two mappings
          existing_mappings = self.source.mappings.where( concept_id: ancestor.id, table: self.table, column: self.column ).status(['mapped', 'unmapped', 'derived']) # TODO: Any status really except outdated...which should just be deleted

          self.source.mappings.create( concept_id: ancestor.id, status: 'derived', value: self.value, table: self.table, column: self.column, column_value: self.column_value, units: self.units ) if existing_mappings.blank?
        end
      end
    end
  end

  def abstract_value(query_concept)
    result = []
    query_concept_value = query_concept.value

    if query_concept.negated? and (self.concept.categorical? or self.concept.boolean?)
      full_set = []
      if self.concept.categorical?
        full_set = self.concept.recommended_concepts.collect{|c| c.id.to_s} + ['unknown']
      elsif self.concept.boolean?
        full_set = ['true', 'false', 'unknown']
      end
      query_concept_value = (full_set - query_concept_value.split(',')).join(',')
    end

    return ['1 = 0'] if query_concept_value.blank?

    if self.concept and self.concept.date?
      result = query_concept_value.to_s.split(',')
    elsif self.concept and self.concept.continuous?
      result = query_concept_value.to_s.split(',')
    elsif self.concept and self.concept.categorical?
      query_concept_value.split(',').each do |concept_id|
        mappings = []
        if concept_id == 'true'
          # TODO: It's True!
          mappings = self.source.mappings.where(concept_id: self.concept.id, value: 'true') # Not quite right?
        elsif concept_id == 'false'
          # TODO: Negation!
          mappings = self.source.mappings.where(concept_id: self.concept.id, value: 'false') # Not quite right?
        elsif concept_id == 'unknown'
          logger.debug "IS UNKNOWN!"
          mappings = self.source.mappings.where(concept_id: self.concept.id, value: 'unknown')
        else
          mappings = self.source.mappings.where(concept_id: concept_id)
        end

        if mappings.size > 0
          mappings.each do |m|
            if m.column_value == 'NULL'
              result << nil
            else
              result << "'" + m.column_value + "'"
            end
          end
        else
          # Did not find Mapping
          result << "1 = 0"
        end
      end
    elsif self.concept and self.concept.boolean?

      # Update query_concept_value to "true" if the query_concept is categorical,
      # this way if searching for Gender:Male and only Male is mapped to true, it finds it correctly
      # But if searching for Lorazepam (false) and only (child) Clobazam is mapped,
      # it still correctly looks for value false, since the original search term was boolean.
      query_concept_value = ['true'] if query_concept.concept.categorical?

      query_concept_value.split(',').each do |value|
        mappings = self.source.mappings.where(concept_id: self.concept.id, value: value)
        if mappings.size > 0
          mappings.each do |m|
            if m.column_value == 'NULL'
              result << nil
            else
              result << "'" + m.column_value + "'"
            end
          end
        else
          result << "1 = 0"
        end
      end
    else # Virtual
      return ['1 = 0']
    end
    result
  end

  # Returns the name of the concept if the mapping is categorical
  # True, False, or Unknown if the mapping is boolean
  # And the value itself if an appropriate match can not be found
  def human_normalized_value(val)
    if self.concept.categorical? or self.concept.boolean?
      val_mapping = self.source.mappings.find_by_table_and_column_and_column_value(self.table, self.column, (val == nil) ? 'NULL' : val.to_s)
      if val_mapping and val_mapping.concept and val_mapping.concept != self.concept and self.concept.categorical?
        val_mapping.concept.human_name
      elsif val_mapping and self.concept.boolean? and val_mapping.value.blank?
        (val_mapping.concept == self.concept) ? 'true' : 'false'
      elsif val_mapping
        val_mapping.value
      else
        val
      end
    else
      val
    end
  end

  def uniq_normalized_value(val)
    if self.concept.categorical? or self.concept.boolean?
      val_mapping = self.source.mappings.find_by_table_and_column_and_column_value(self.table, self.column, (val == nil) ? 'NULL' : val.to_s)
      if val_mapping and val_mapping.concept and val_mapping.concept != self.concept and self.concept.categorical?
        val_mapping.concept_id
      elsif val_mapping
        val_mapping.value
      else
        val
      end
    else
      val
    end
  end

  def human_units
    concept = Concept.find_by_name(self.units)
    if concept
      concept.human_units
    else
      self.units.to_s.split('#').last || ''
    end
  end

  def graph_values_short(current_user, chart_params)
    value_hash = self.all_values_for_column(current_user)
    values = value_hash[:values]

    result = value_hash[:error].to_s
    error = value_hash[:error].to_s

    stats = column_statistics_given_values(values)

    if values.size > 0
      if self.concept.continuous? # or self.concept.date?
        values = values.select{|v| not v.blank?}.collect{|num_string| num_string.to_i} # Ignore null and blank values!
      elsif self.concept.categorical? or self.concept.boolean?
        value_hash = {}
        values.sort{|a,b|( a and b ) ? a <=> b : ( a ? -1 : 1 ) }.group_by{|val| val}.each do |key, array|
          orig_key = key
          key = '&lt;![CDATA[]]&gt;' if key == ''
          value_hash[(key == nil ? "NULL" : key.to_s.gsub('&lt;![CDATA[', '"').gsub(']]&gt;', '"').gsub(' ', '_').gsub("'", '\\\\\'')) + ': ' + self.uniq_normalized_value(orig_key).to_s.gsub("'", '\\\\\'')] = array.size
        end
        value_array = []
        values.sort{|a,b|( a and b ) ? a <=> b : ( a ? -1 : 1 ) }.group_by{|val| val}.each do |key, array|
          orig_key = key
          key = '&lt;![CDATA[]]&gt;' if key == ''
          value_array << { name: "#{self.human_normalized_value(orig_key).to_s.gsub("'", '\\\\\'')} in #{self.source.name.gsub("'", '\\\\\'')}", y: array.size, id: uniq_normalized_value(orig_key).to_s.gsub("'", '\\\\\'') }
        end
      else
        error += ": No Chart for #{self.concept.concept_type} Concepts Provided"
      end
    else
      error += ": No Values In Database For this Column"
    end

    { local_values: values, value_array: value_array, error: error }
  end

  def graph_values(current_user, chart_params)
    categories = []
    value_hash = self.all_values_for_column(current_user)
    values = value_hash[:values]

    result = value_hash[:error].to_s
    error = value_hash[:error].to_s

    stats = column_statistics_given_values(values)

    if values.size > 0
      if self.concept.continuous? # or self.concept.date?
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
      elsif self.concept.categorical? or self.concept.boolean?
        value_hash = {}
        # logger.debug "values: #{values.inspect}"
        values.sort{|a,b|( a and b ) ? a <=> b : ( a ? -1 : 1 ) }.group_by{|val| val}.each do |key, array|
          orig_key = key
          key = '&lt;![CDATA[]]&gt;' if key == ''
          value_hash[(key == nil ? "NULL" : key.to_s.gsub('&lt;![CDATA[', '"').gsub(']]&gt;', '"').gsub(' ', '_').gsub("'", '\\\\\'')) + ': ' + self.uniq_normalized_value(orig_key).to_s.gsub("'", '\\\\\'')] = array.size
        end
        value_array = []
        values.sort{|a,b|( a and b ) ? a <=> b : ( a ? -1 : 1 ) }.group_by{|val| val}.each do |key, array|
          orig_key = key
          key = '&lt;![CDATA[]]&gt;' if key == ''
          value_array << { name: "#{self.human_normalized_value(orig_key).to_s.gsub("'", '\\\\\'')}", y: array.size, id: uniq_normalized_value(orig_key).to_s.gsub("'", '\\\\\'') }
        end
      else
        error += ": No Chart for #{self.concept.concept_type} Concepts Provided"
      end
      # page.replace_html "mapping_#{self.column_name.gsub(' ', '_')}_stats", "<table><tr><td>"+self.column_statistics_given_values(values) + "</td><td>" + result +"</td></tr></table>"
    else
      error += ": No Values In Database For this Column"
    end

    # return {value_hash: value_hash, values: values, categories: categories, error: error}

    key_name = "#{self.source.name}.#{self.column}"

    if self.concept.continuous? or self.concept.date?
      chart_type = "column"
      values = { key_name => values }
      chart_element_id = "column_chart_#{self.concept.id}"
    elsif self.concept.categorical? or self.concept.boolean?
      chart_type = "pie"
      # values = value_hash
      values = { key_name => value_array }
      chart_element_id = "pie_chart_#{self.concept.id}"
    end

    defaults = { width: "320px", height: 240, units: '', title: '', legend: 'right' }

    defaults.merge!(chart_params)


    { values: values, categories: categories, chart_type: chart_type, defaults: defaults, chart_element_id: chart_element_id, error: error, stats: stats }
  end

  def destroy(real_destroy = false)
    if real_destroy
      super()
    else
      update_attributes(deleted: true, status: 'unmapped', concept_id: nil, value: nil, units: nil)
    end
  end

  # Returns whether the user can see the mapping given a set of valid source rules
  def user_can_view?(current_user, actions_required)
    sensitive_concept = (self.concept and self.concept.sensitivity != '0')
    return true if actions_required.include?('download files') and self.source.user_has_action?(current_user, 'download files')
    return true if actions_required.include?('download dataset') and self.source.user_has_action?(current_user, 'download dataset')
    return true if actions_required.include?('view data distribution') and self.source.user_has_action?(current_user, 'view data distribution')

    return true if actions_required.include?('download limited dataset') and self.source.user_has_action?(current_user, 'download limited dataset') and not sensitive_concept
    return true if actions_required.include?('view limited data distribution') and self.source.user_has_action?(current_user, 'view limited data distribution') and not sensitive_concept

    return false
  end

  # automap mapping to c
  def automap(current_user, c, column_hash)

    @source = self.source

    self.update_attributes(units: c.units, concept_id: c.id, deleted: false)

    if c.categorical?
      column_values = self.column_values(current_user)
      column_values.each do |column_value|
        if column_value == nil
          val_mapping = @source.mappings.where( table: table, column: column_hash[:column], column_value: 'NULL' ).first_or_create
          val_mapping.update_attributes(concept_id: c.id, value: 'unknown', status: 'mapped', deleted: false)
        else
          internal_term_found = false
          c.recommended_concepts.each do |recommended_concept|
            recommended_concept.internal_terms.each do |internal_term|
              if internal_term.name.downcase == column_value.to_s.downcase and not internal_term_found
                val_mapping = @source.mappings.where( table: table, column: column_hash[:column], column_value: column_value.to_s ).first_or_create
                val_mapping.update_attributes(concept_id: recommended_concept.id, value: nil, status: 'mapped', deleted: false)
                internal_term_found = true
              end
            end
          end

          unless internal_term_found
            val_mapping = @source.mappings.where( table: table, column: column_hash[:column], column_value: column_value.to_s ).first_or_create
            val_mapping.update_attributes(concept_id: c.id, value: nil, status: 'unmapped', deleted: false)
          end
        end
      end
    elsif c.boolean?
      column_values = self.column_values(current_user)
      column_values.each do |column_value|
        status = 'mapped'
        value = nil # Important, nil value is different than "unknown"

        if column_value == nil or ['-1'].include?(column_value.to_s.downcase)
          cv = (column_value == nil ? 'NULL' : column_value.to_s)
          value = 'unknown'
        elsif ['0','f', 'false'].include?(column_value.to_s.downcase)
          cv = column_value.to_s
          value = 'false'
        elsif ['1','t', 'true'].include?(column_value.to_s.downcase)
          cv = column_value.to_s
          value = 'true'
        else
          cv = column_value.to_s
          # value = nil # This is essentially set here.
          status = 'unmapped'
        end

        val_mapping = @source.mappings.where( table: table, column: column_hash[:column], column_value: cv ).first_or_create
        val_mapping.update_attributes(concept_id: c.id, value: value, status: status, deleted: false)
      end
    end

    self.reload
    # TODO: Remove Mappings that no longer exist in the underlying data source
    # mapping.database_concept_column_values.where(["time_stamp != ?", current_time]).each {|dccv| dccv.destroy}
    self.set_status!(current_user)

    # Currently only derives mappings for continuous concepts
    self.generate_derived!
  end

  private

  def std_dev(population)
    def variance(pop)
      return nil if pop.empty?
      n = 0
      mean = 0.0
      s = 0.0
      pop.each { |x|
        n = n + 1
        delta = x - mean
        mean = mean + (delta / n)
        s = s + delta * (x - mean)
      }
      # if you want to calculate std deviation
      # of a sample change this to "s / (n-1)"
      return s / n
    end
    Math.sqrt(variance(population))
  end

  # include ActionView::Helpers::UrlHelper # For array_or_string_for_javascript  (also in ScriptaculousHelper)
  def array_or_string_for_javascript(option)
    if option.kind_of?(Array)
      "['#{option.join('\',\'')}']"
    elsif !option.nil?
      "'#{option}'"
    end
  end
end
