class Subscription < ApplicationRecord
  belongs_to :user

  PLAN_TYPES = %w[free basic premium].freeze
  STATUSES = %w[active inactive cancelled].freeze

  validates :plan_type, presence: true, inclusion: { in: PLAN_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
end
