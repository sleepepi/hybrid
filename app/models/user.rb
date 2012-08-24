class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, and :lockable
  devise :database_authenticatable, :registerable, :timeoutable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name, :email_notifications

  after_create :notify_system_admins

  STATUS = ["active", "denied", "inactive", "pending"].collect{|i| [i,i]}
  serialize :email_notifications, Hash

  # Named Scopes
  scope :current, conditions: { deleted: false }
  scope :status, lambda { |*args|  { conditions: ["users.status IN (?)", args.first] } }
  scope :search, lambda { |*args| { conditions: [ 'LOWER(first_name) LIKE ? or LOWER(last_name) LIKE ? or LOWER(email) LIKE ?', '%' + args.first.downcase.split(' ').join('%') + '%', '%' + args.first.downcase.split(' ').join('%') + '%', '%' + args.first.downcase.split(' ').join('%') + '%' ] } }
  scope :system_admins, conditions: { system_admin: true }

  # Model Validation
  validates_presence_of     :first_name
  validates_presence_of     :last_name

  # Model Relationships
  has_many :authentications

  has_many :file_types

  has_many :dictionaries, conditions: { deleted: false }

  has_many :queries, conditions: { deleted: false } #, order: 'updated_at DESC'
  has_many :query_users
  has_many :shared_queries, through: :query_users, source: :query, order: 'name', conditions: ['queries.deleted = ?', false]

  has_many :reports

  has_many :true_datasets, class_name: "Report", conditions: { is_dataset: true }, order: '(reports.name IS NULL or reports.name = ""), reports.name, reports.id'
  has_many :true_reports, class_name: "Report", conditions: { is_dataset: false }, order: '(reports.name IS NULL or reports.name = ""), reports.name, reports.id'

  has_many :sources, conditions: { deleted: false }

  # User Methods

  def all_dictionaries
    @all_dictionaries ||= begin
      self.dictionaries
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

  def all_source_joins
    @all_source_joins ||= begin
      self.system_admin? ? SourceJoin.current : []
    end
  end

  # Overriding Devise built-in active_for_authentication? method
  def active_for_authentication?
    super and self.status == 'active' and not self.deleted?
  end

  def destroy
    update_column :deleted, true
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

  def nickname
    "#{first_name} #{last_name.first}"
  end

  def name_and_email
    "#{first_name} #{last_name} &lsaquo;#{email}&rsaquo;"
  end

  def apply_omniauth(omniauth)
    unless omniauth['info'].blank?
      self.email = omniauth['info']['email'] if email.blank?
      self.first_name = omniauth['info']['first_name'] if first_name.blank?
      self.last_name = omniauth['info']['last_name'] if last_name.blank?
    end
    authentications.build( provider: omniauth['provider'], uid: omniauth['uid'] )
  end

  def password_required?
    (authentications.empty? || !password.blank?) && super
  end

  private

  def notify_system_admins
    User.current.system_admins.each do |system_admin|
      UserMailer.notify_system_admin(system_admin, self).deliver if Rails.env.production? and system_admin.email_on?(:send_email)
    end
  end
end
