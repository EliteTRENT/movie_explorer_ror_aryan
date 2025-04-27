class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :validatable, :jwt_authenticatable, jwt_revocation_strategy: self

  enum role: { user: 0, supervisor: 1 }

  validates :name, presence: true, length: { maximum: 100, minimum: 3 }
  validates :mobile_number, presence: true, format: { with: /\A(\+?[1-9]\d{0,3})?\d{9,14}\z/ }, uniqueness: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  scope :by_role, ->(role) { where(role: role) }
  scope :recent, -> { order(created_at: :desc) }

  def jwt_payload
    { 'role' => role }
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email", "id", "name", "mobile_number", "role", "updated_at"]
  end
  def self.ransackable_associations(auth_object = nil)
    [] 
  end
end