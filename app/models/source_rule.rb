class SourceRule < ActiveRecord::Base
  belongs_to :source
  serialize :actions, Array
  serialize :users, Array

  attr_reader :user_tokens

  ACTION_GROUPS = [["All Read", ["view data source general information"]],
                   ["All Write", ["edit data source connection information", "edit data source mappings", "edit data source rules"]],
                   ["All Data", ["get count", "view limited data distribution", "view data distribution", "download limited dataset", "download dataset", "download files"]]]

  ACTION_GROUPS_SELECT = ACTION_GROUPS.collect{||}

  def name
    self.read_attribute('name').blank? ? "ID ##{self.id}" : self.read_attribute('name')
  end

  def user_tokens=(ids)
    self.users = ids.to_s.split(',')
  end

  def self.action_group_items(action_group)
    ACTION_GROUPS.each do |group|
      return group[1] if group[0] == action_group
    end
    []
  end

  # This doesn't take into consideration if the user is blocked, this needs to be determined using all source_rules from the source
  def user_has_action?(current_user, action)
    return (self.has_user?(current_user.id) and self.has_action?(action))
  end

  def has_user?(user_id)
    return (self.users || []).include?(user_id.to_s)
  end

  def has_action?(action)
    return (self.actions || []).include?(action)
  end
end
