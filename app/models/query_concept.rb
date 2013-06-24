class QueryConcept < ActiveRecord::Base

  OPERATOR = ["and", "or"].collect{|i| [i,i]}

  # Callbacks
  after_create :create_qc_query_history
  before_update :update_qc_query_history

  # Concerns
  include Deletable

  # Model Relationships
  belongs_to :query
  belongs_to :concept
  belongs_to :source

  # Query Concept Methods

  def concept_name_with_source
    full_name = "#{self.concept.human_name}"
    full_name += " at #{self.source.name}" if self.source and self.source != self.query.sources.first and self.query.sources.size != 1
    full_name
  end

  def source
    if self.source_id and selected_source = Source.find_by_id(self.source_id)
      selected_source
    else
      self.concept.sources.first
    end
  end

  def copyable_attributes
    self.attributes.reject{|key, val| ['id', 'query_id', 'deleted', 'created_at', 'updated_at'].include?(key.to_s)}
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
