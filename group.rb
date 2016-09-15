class Group < ActiveRecord::Base
  include Statusable

  validates :name, presence: true

  has_and_belongs_to_many :users
  has_and_belongs_to_many :subscriptions

  has_one :mailing

  after_save :assign_users
  after_save :check_mailing

  accepts_nested_attributes_for :mailing, reject_if: :all_blank

  bitmask :system_type, as: [:automatic, :mailing], null: false

  scope :with_all, -> do
    eager_load(:users, :subscriptions)
  end

  scope :with_mailing, -> do
    eager_load(:mailing)
  end

  class << self
    def assign_user user
      with_system_type(:automatic).each do |group|
        group.users << Receiv.where(subscription_id: group.subs_ids, user_id: user.id).collect(&:user) if !group.user_ids.include? user.id
      end
    end
  end

  def to_table
    attributes.merge subscriptions: subscriptions.count,
      users: users.count,
      is_mailing: system_type?(:mailing)
  end

  def assign_users
    return if !system_type? :automatic
    self.user_ids = Receiv.where(subscription_id: subs_ids).pluck(:user_id)
  end

  def mailing
    return if !system_type? :mailing
    super
  end

  private
  def check_mailing
    return if !system_type? :mailing
    create_mailing if !mailing
  end
end
