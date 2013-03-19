class QueryConcept < ActiveRecord::Base

  OPERATOR = ["and", "or"].collect{|i| [i,i]}

  # Callbacks
  after_create :create_qc_query_history
  before_update :update_qc_query_history

  # Concerns
  include Deletable

  # Model Relationships
  belongs_to :query #, touch: true # Possibly not needed due to undo/redo actions
  belongs_to :concept

  # Only for external keys
  belongs_to :source

  # Query Concept Methods

  def copyable_attributes
    self.attributes.reject{|key, val| ['id', 'query_id', 'deleted', 'created_at', 'updated_at'].include?(key.to_s)}
  end

  def construct_sql(current_user, source = nil)
    return { conditions: '1 = 0', tables: [], error: "#{self.concept.human_name} in #{source.name} is sensitive and requires <span class='source_rule_text'>view data distribution</span>." } if source and not source.user_has_action?(current_user, 'view data distribution') and self.concept.sensitivity != '0'

    result_hash = source.sql_codes(current_user)
    sql_text = result_hash[:text]
    sql_numeric = result_hash[:numeric]
    sql_open = result_hash[:open]
    sql_close = result_hash[:close]

    result = ''

    if self.concept
      conditions = []

      # If the concept itself is categorical, then we want to immediately figure out which "children concepts" of the concept are specified in the values
      mapped_descendants = []
      if self.concept.categorical?
        mapped_descendants = source.mappings.where(concept_id: self.concept_id, status: 'mapped').to_a
        # Other concepts such as Male or Female might be mapped elsewhere too, so check for these also.
        self.value.to_s.split(',').each do |concept_id|
          if sub_concept = Concept.find_by_id(concept_id)
            mapped_descendants << sub_concept.mapped_descendants(source)
            mapped_descendants.flatten!
            mapped_descendants.uniq!
          end
        end
      else
        mapped_descendants = self.concept.mapped_descendants(source)
      end

      if mapped_descendants.blank? and source.linked_concepts.where(["concepts.id = ?", self.concept.id]).size > 0
        return self.linked_sql(current_user, source)
      elsif mapped_descendants.blank?
        return { conditions: '1 = 0', tables: [], error: '' }
      end

      overall_conditions = []

      # These should all be OR'd together
      mapped_descendants.each do |mapped_descendant|
        mapped_name = mapped_descendant.table + '.' + sql_open + mapped_descendant.column + sql_close
        values = mapped_descendant.abstract_value(self)

        if values.blank?
          conditions << '1 = 0'
        else
          values.each do |val|
            token_hash = self.find_tokens(val)

            token = token_hash[:token]
            val = token_hash[:val]
            left_token = token_hash[:left_token]
            right_token = token_hash[:right_token]
            range = token_hash[:range]

            if val == nil
              conditions << "#{mapped_name} IS NULL"
            elsif val == '1 = 0' or (range.size == 1 and range[0].blank?) or (range.size == 2 and range[0].blank? and range[1].blank?)
              conditions << '1 = 0'
            elsif self.concept.date?
              # if range.size == 2
                if range[0].blank? # From is empty, so every date less or equal to the to date
                  conditions << "DATE(#{mapped_name}) <= DATE('#{range[1]}')"
                elsif range[1].blank? # To is empty, so every date greater or equal to the from date
                  conditions << "DATE(#{mapped_name}) >= DATE('#{range[0]}')"
                else
                  conditions << "DATE(#{mapped_name}) BETWEEN DATE('#{range[0]}') and DATE('#{range[1]}')"
                end
              # else
              #   conditions << "DATE(#{mapped_name}) #{token} DATE('#{range[0]}')"
              # end
            elsif self.concept.continuous?
              numeric_string = sql_numeric.blank? ? "(#{mapped_name}+0.0)" : "CAST(#{mapped_name} AS #{sql_numeric})"
              if range.size == 2
                if left_token.blank? and right_token.blank?
                  conditions << "#{numeric_string} BETWEEN #{range[0]} and #{range[1]}"
                else
                  conditions << "#{numeric_string} #{left_token} #{range[0]} and #{numeric_string} #{right_token} #{range[1]}"
                end
              else
                conditions << "#{numeric_string} #{token} #{range[0]}"
              end
            else
              conditions << "CAST(#{mapped_name} AS #{sql_text}) = #{val}"
            end
          end
        end
      end
      invert_container = (self.negated? and not (self.concept.boolean? or self.concept.categorical?))
      result = "#{'NOT ' if invert_container}(" + conditions.uniq.join(' or ') + ')'
    else
      result = '1 = 0'
    end

    { conditions: result, tables: [], error: '' }
  end

  # Returns the value of the string as a human readable value
  def human_value
    result = ''
    if self.concept and self.concept.continuous?
      result = token_ranges
    elsif self.concept and self.concept.categorical?
      result = self.value.to_s.split(',').collect{|c_id| Concept.find_by_id(c_id)}.compact().collect{|c| "#{c.human_name}"}.join(' <span class="nolink">or</span> ').html_safe
    elsif self.concept and self.concept.boolean?
      result = self.value.to_s.split(',').collect{|c| "#{c}"}.join(' <span class="nolink">or</span> ').html_safe
    elsif self.concept and self.concept.date?
      start_date = self.value.to_s.split(':')[0]
      end_date = self.value.to_s.split(':')[1]
      result << "<span class='nolink'>on or after</span> #{start_date}" unless start_date.blank?
      result << " <span class='nolink'>and</span> " unless start_date.blank? or end_date.blank?
      result << "<span class='nolink'>on or before</span> #{end_date}" unless end_date.blank?
      result = result.html_safe
    elsif self.concept and self.concept.identifier?
      result = "Identifier [#{self.value}]"
    elsif self.concept and self.concept.file_locator?
      result = "File Locator [#{self.value}]"
    elsif self.concept and self.concept.free_text?
      result = "Free Text [#{self.value}]"
    end
    result
  end

  def token_ranges
    result = ''

    u = self.concept.units.to_s.split('#').last.to_s.humanize.downcase
    u_singular = ''
    u_plural = ''
    unless u.blank?
      u_singular = u.split(' ')[0].singularize + ' ' + u.split(' ')[1..-1].join(' ')
      u_plural = (u.split(' ')[0] == 'percent' ? 'percent' : u.split(' ')[0].pluralize) + ' ' + u.split(' ')[1..-1].join(' ')
    end

    results = []

    self.value.to_s.split(',').each do |val|
      token_hash = self.find_tokens(val)
      token = token_hash[:token]
      val = token_hash[:val]
      left_token = token_hash[:left_token]
      right_token = token_hash[:right_token]
      range = token_hash[:range]

      if range.size == 2
        if left_token.blank? and right_token.blank?
          results << "between <b>#{range[0]}</b> and <b>#{range[1]}</b> #{u_plural}"
        else
          results << "#{left_token} <b>#{range[0]}</b> and #{right_token} <b>#{range[1]}</b> #{u_plural}"
        end
      else
        results << "#{token unless token == '='} <b>#{val}</b> #{val == "1" ? u_singular : u_plural}"
      end
    end

    result = results.join(' or ').html_safe
  end


  # Values can include:
  #        concept_ids:     1234,5678
  #            boolean:     false,true
  #               null:     nil
  #             ranges:     x:y
  #                         [x:y]
  #                         (x:y]
  #                         [x:y)
  #                         (x:y)
  #                         <=x
  #                         <x
  #                         >x
  #                         >=x
  #  individual values:     18.0,-5,2000
  def find_tokens(val)
    token = '='
    if token_match = val.to_s.strip.match(/^<=|^>=|^<|^>|^=/)
      token = token_match[0]
      val = val.to_s.strip.sub(token, '') # First instance only
    elsif token_match = val.to_s.strip.match(/^([\(|\[])?([^\[\]\(\)]+?)(\]|\))?$/)
      left_token = (token_match[1] == '[') ? '>=' : '>'
      val = token_match[2].to_s.strip
      right_token = (token_match[3] == ']') ? '<=' : '<'
      if token_match[1].blank? and token_match[3].blank?
        left_token = nil
        right_token = nil
      end
    end
    range = val.to_s.split(':')
    { token: token, val: val, left_token: left_token, right_token: right_token, range: range }
  end

  def linked_sql(current_user, source)
    tables = []
    result_hash = source.sql_codes(current_user)
    sql_open = result_hash[:open]
    sql_close = result_hash[:close]

    conditions = ''
    all_conditions = []
    source.all_linked_sources(concept.id).each do |s|
      table = ''
      column = ''
      source_join = SourceJoin.find_by_source_id_and_source_to_id(source.id, s.id)
      rev_join = SourceJoin.find_by_source_id_and_source_to_id(s.id, source.id)
      if source_join
        table = source_join.from_table
        column = source_join.from_column
        table2 = source_join.to_table
        column2 = source_join.to_column
      elsif rev_join
        table = rev_join.to_table
        column = rev_join.to_column
        table2 = rev_join.from_table
        column2 = rev_join.from_column
      end

      tables << table

      result_hash = self.query.view_concept_values(current_user, [s], [], [self], [{table: table2, column: column2}])
      # puts result_hash[:error]
      if result_hash[:error].blank? and not table.blank? and not column.blank?
        all_conditions << "#{table}.#{sql_open}#{column}#{sql_close} IN (#{result_hash[:result][1..-1].collect{|r| r.first.kind_of?(String) ? "'" + r.first.gsub("'", "\\\\'") + "'" : r.first.to_s}.join(', ')})" if result_hash[:result][1..-1].size > 0
      end
    end

    conditions = all_conditions.blank? ? '1 = 0' : '(' + all_conditions.join(' or ') + ')'
    { conditions: conditions, tables: tables.compact.uniq, error: '' }
  end

  def construct_sql_wrap(current_user, source = nil, temp_query_concepts = self.query.query_concepts)
    conditions = ''

    if temp_query_concepts.size == 1
      result_hash = self.construct_sql(current_user, source)
      conditions = result_hash[:conditions]
    else
      result_hash = self.construct_sql(current_user, source)
      conditions = "("*self.left_brackets + result_hash[:conditions] + ")"*self.right_brackets + (self.position < (temp_query_concepts.size - 1) ? " #{self.right_operator}" : '')
    end

    { conditions: conditions, tables: result_hash[:tables], error: result_hash[:error] }
  end

  def external_concept_information(current_user)
    @external_concept_information ||= begin
      information = {name: self.external_key}
      if self.source
        result_hash = self.source.external_concept_information(current_user, self.external_key)
        information = result_hash[:result] if result_hash[:error].blank?
      end
      information
    end
  end

  # Overwrites deletable since it relies on callbacks
  def destroy
    update_attributes deleted: true
    self.query.update_positions if self.query
  end

  def undestroy
    update_attributes deleted: false
    self.query.update_positions if self.query
  end

  # After Create Action
  def create_qc_query_history
    self.query.roll_forward_query_history!
    self.query.history << { action: 'create', id: self.id }
    self.query.history_position = self.query.history.size
    self.query.save!
  end

  def update_qc_query_history
    # Don't include right_brackets, left_brackets, or position updates
    if self.changes.blank? or self.changes.keys.include?('right_brackets') or self.changes.keys.include?('left_brackets') or self.changes.keys.include?('position') or self.changes.keys.include?('selected')
      # Rails.logger.debug "No update for these changes: #{self.changes}"
    else
      self.query.roll_forward_query_history!

      self.query.history << { action: 'update', id: self.id, changes: self.changes }
      self.query.history_position = self.query.history.size
      self.query.save!
    end
  end
end
