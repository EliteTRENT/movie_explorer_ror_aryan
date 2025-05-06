class Subscription < ApplicationRecord
  belongs_to :user

  PLAN_TYPES = %w[basic premium].freeze
  STATUSES = %w[active inactive cancelled].freeze

  validates :plan_type, presence: true, inclusion: { in: PLAN_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  def basic?; plan_type == 'basic'; end
  def premium?; plan_type == 'premium'; end
end
