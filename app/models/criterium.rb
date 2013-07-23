# Criterium VS Criterion
# I wanted to use Criteria plural (for "search criteria") as criteria is commonly used.
# Rails howver thinks the singular version of that is Criterium
#   Criterion -> Criterions
#   Criterium -> Criteria
# While I could monkey patch ActiveRecord to use Criterion -> Criteria
# to account for the more commonly used English words,
# the added complexity (and potential nuances) is (are) not worth it
# So in this code base, use Criterium for singular and Criteria for plural.

class Criterium < ActiveRecord::Base

  OPERATOR = ["and", "or"]

  # Callbacks
  after_create :create_search_history
  before_update :update_search_history

  # Concerns
  include Deletable

  # Model Validation
  validates_presence_of :search_id, :variable_id, :position

  # Model Relationships
  belongs_to :search
  belongs_to :variable
  belongs_to :source

  # Criterium Methods

  def variable_name_with_source
    full_name = "#{self.variable.display_name}"
    full_name += " at #{self.source.name}" if self.source and (self.source != self.search.sources.first or self.search.sources.size != 1)
    full_name
  end

  # def concept_name_with_source
  #   full_name = "#{self.concept.human_name}"
  #   full_name += " at #{self.source.name}" if self.source and (self.source != self.search.sources.first or self.search.sources.size != 1)
  #   full_name
  # end

  def source
    if self.source_id and selected_source = Source.find_by_id(self.source_id)
      selected_source
    else
      self.variable.sources.first
    end
  end

  def copyable_attributes
    self.attributes.reject{|key, val| ['id', 'search_id', 'deleted', 'created_at', 'updated_at'].include?(key.to_s)}
  end

  def human_value
    case self.variable.variable_type when 'integer', 'numeric'
      token_ranges
    when 'choices'
      self.variable.domain.options.select{|option| self.value.to_s.split(',').include?(option[:value].to_s)}.collect{|option| option[:display_name]}.join(' <span class="nolink">or</span> ').html_safe
      # self.value.to_s.split(',').collect{|v| self.variable.domain.options.select{|opt| opt[:value].to_s == v.to_s}.collect{|opt| opt[:display_name]}} #.join(' <span class="nolink">or</span> ').html_safe
    when 'date'
      start_date = self.value.to_s.split(':')[0]
      end_date = self.value.to_s.split(':')[1]
      result = ''
      result << "<span class='nolink'>on or after</span> #{start_date}" unless start_date.blank?
      result << " <span class='nolink'>and</span> " unless start_date.blank? or end_date.blank?
      result << "<span class='nolink'>on or before</span> #{end_date}" unless end_date.blank?
      result.html_safe
    else
      "#{self.variable.variable_type} [#{self.value}]"
    end
  end

  def token_ranges
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
          results << "between <b>#{range[0]}</b> and <b>#{range[1]}</b> #{self.variable.units}"
        else
          results << "#{left_token} <b>#{range[0]}</b> and #{right_token} <b>#{range[1]}</b> #{self.variable.units}"
        end
      else
        results << "#{token unless token == '='} <b>#{val}</b> #{self.variable.units}"
      end
    end

    results.join(' or ').html_safe
  end


  # Values can include:
  #        concept_ids:     1234,5678
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
    self.update deleted: true
    self.search.update_positions
  end

  def undestroy
    self.update deleted: false
    self.search.update_positions
  end

  # After Create Action
  def create_search_history
    self.search.roll_forward_search_history!
    self.search.history << { action: 'create', id: self.id }
    self.search.history_position = self.search.history.size
    self.search.save!
  end

  def update_search_history
    # Don't include right_brackets, left_brackets, or position updates
    if self.changes.blank? or self.changes.keys.include?('right_brackets') or self.changes.keys.include?('left_brackets') or self.changes.keys.include?('position') or self.changes.keys.include?('selected')
      # "No update for these changes: #{self.changes}"
    else
      self.search.roll_forward_search_history!

      self.search.history << { action: 'update', id: self.id, changes: self.changes }
      self.search.history_position = self.search.history.size
      self.search.save!
    end
  end
end
