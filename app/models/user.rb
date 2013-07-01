class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, and :lockable
  devise :database_authenticatable, :registerable, :timeoutable,
         :recoverable, :rememberable, :trackable, :validatable

  after_create :notify_system_admins

  STATUS = ["active", "denied", "inactive", "pending"].collect{|i| [i,i]}
  serialize :email_notifications, Hash

  # Concerns
  include Deletable, Contourable

  # Named Scopes
  scope :status, lambda { |arg|  where( status: arg ) }
  scope :search, lambda { |arg| where( 'LOWER(first_name) LIKE ? or LOWER(last_name) LIKE ? or LOWER(email) LIKE ?', arg.to_s.downcase.gsub(/^| |$/, '%'), arg.to_s.downcase.gsub(/^| |$/, '%'), arg.to_s.downcase.gsub(/^| |$/, '%') ) }
  scope :system_admins, -> { where system_admin: true }

  # Model Validation
  validates_presence_of     :first_name
  validates_presence_of     :last_name

  # Model Relationships
  has_many :file_types
  has_many :dictionaries, -> { where deleted: false }

  has_many :queries, -> { where deleted: false }
  has_many :query_users
  has_many :shared_queries, -> { where( deleted: false ).order( 'name' ) }, through: :query_users, source: :query

  has_many :reports

  has_many :true_datasets, -> { where(is_dataset: true).order('(reports.name IS NULL or reports.name = ""), reports.name, reports.id') }, class_name: "Report"
  has_many :true_reports, -> { where(is_dataset: false).order('(reports.name IS NULL or reports.name = ""), reports.name, reports.id') }, class_name: "Report"

  has_many :sources, -> { where deleted: false }

  # User Methods

  def all_dictionaries
    @all_dictionaries ||= begin
      self.dictionaries
    end
  end

  def all_viewable_dictionaries
    @all_viewable_dictionaries ||= begin
      Dictionary.current.where("user_id = ? or visible = ?", self.id, true)
    end
  end

  def all_queries
    @all_queries ||= begin
      ::Query.current.with_user(self.id)
    end
  end

  def all_sources
    @all_sources ||= begin
      self.sources
    end
  end

  # Overriding Devise built-in active_for_authentication? method
  def active_for_authentication?
    super and self.status == 'active' and not self.deleted?
  end

  def destroy
    super
    update_column :status, 'inactive'
    update_column :updated_at, Time.now
  end

  def email_on?(value)
    self.active_for_authentication? and [nil, true].include?(self.email_notifications[value.to_s])
  end

  def name
    "#{first_name} #{last_name}"
  end

  def reverse_name
    "#{last_name}, #{first_name}"
  end

  def name_and_email
    "#{first_name} #{last_name} &lsaquo;#{email}&rsaquo;"
  end

  # Override of Contourable
  def apply_omniauth(omniauth)
    unless omniauth['info'].blank?
      self.first_name = omniauth['info']['first_name'] if first_name.blank?
      self.last_name = omniauth['info']['last_name'] if last_name.blank?
    end
    super
  end

  private

  def notify_system_admins
    User.current.system_admins.each do |system_admin|
      UserMailer.notify_system_admin(system_admin, self).deliver if Rails.env.production? and system_admin.email_on?(:send_email)
    end
  end
end
