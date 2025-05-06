class User < ApplicationRecord
  has_one :subscription, dependent: :destroy
  after_create :create_default_subscription
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :validatable, :jwt_authenticatable, jwt_revocation_strategy: self

  enum role: { user: 0, supervisor: 1 }

  validates :name, presence: true, length: { maximum: 100, minimum: 3 }
  validates :mobile_number, presence: true, format: { with: /\A(\+?[1-9]\d{0,3})?\d{9,14}\z/ }, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :notifications_enabled, inclusion: { in: [true, false] }
  validates :password, format: { with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}\z/, message: "must include at least one uppercase letter, one lowercase letter, one digit, and one special character" }, if: :password_present?
  validates :jti, uniqueness: true

  scope :by_role, ->(role) { where(role: role) }
  scope :recent, -> { order(created_at: :desc) }

  def jwt_payload
    { 'role' => role }
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email", "id", "name", "mobile_number", "role", "updated_at", "notifications_enabled"]
  end

  def self.ransackable_associations(auth_object = nil)
    [] 
  end

  private 

  def password_present?
    password.present?
  end
  
  def create_default_subscription
    begin 
      customer = Stripe::Customer.create(email: email)
      Subscription.create!(user: self, plan_type: 'basic', status: 'active', stripe_customer_id: customer.id)
    rescue Stripe::StripeError => e
      Rails.logger.error("Failed to create Stripe customer for user #{id}: #{e.message}")
      Subscription.create!(user: self, plan_type: 'basic', status: 'active')
    end
  end
end