class Movie < ApplicationRecord
  after_create :send_new_movie_notification
  has_one_attached :poster
  has_one_attached :banner

  validates :title, presence: true
  validates :genre, presence: true
  validates :release_year, numericality: { only_integer: true, greater_than: 1880, less_than_or_equal_to: Date.current.year }
  validates :rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }, allow_nil: true
  validates :director, presence: true
  validates :duration, numericality: { only_integer: true, greater_than: 0 }
  validates :description, presence: true, length: { maximum: 1000 }
  validate :poster_content_type, if: :poster_attached?
  validate :banner_content_type, if: :banner_attached?

  scope :premium, -> { where(premium: true) }
  scope :accessible_to_user, ->(user) { user&.subscription&.plan_type == 'premium'  ? all : where(premium: false) }

  def poster_attached?
    poster.attached?
  end

  def banner_attached?
    banner.attached?
  end

  private

  def poster_content_type
    unless poster.content_type.in?(%w[image/jpeg image/png])
      errors.add(:poster, 'must be a JPEG or PNG image')
    end
  end

  def banner_content_type
    unless banner.content_type.in?(%w[image/jpeg image/png])
      errors.add(:banner, 'must be a JPEG or PNG image')
    end
  end

  def self.ransackable_associations(auth_object = nil)
    ["banner_attachment", "banner_blob", "poster_attachment", "poster_blob"]
  end
  
  def self.ransackable_attributes(auth_object = nil)
    %w[title genre release_year director duration description premium rating]
  end

  def send_new_movie_notification
    users = User.where(notifications_enabled: true).where.not(device_token: nil)
    return if users.empty?
    device_tokens = users.pluck(:device_token).map(&:to_s).reject(&:blank?).uniq
    return if device_tokens.empty?
    begin
      fcm_service = FcmService.new
      banner_url = banner_attached? ? banner.url : nil
      response = fcm_service.send_notification(device_tokens, "New Movie Added!", "#{title} has been added to the Movie Explorer collection.", { movie_id: id.to_s, banner_url: banner_url})
      if response[:status_code] != 200
        Rails.logger.error("FCM notification failed: #{response[:body]}")
        return { status: 'error', message: response[:body], invalid_tokens: response[:invalid_tokens] }
      end
      Rails.logger.info("FCM notification sent successfully for movie #{id}")
      { status: 'success', message: 'Notification sent successfully' }
    rescue StandardError => e
      Rails.logger.error("FCM notification error: #{e.message}")
      return { status: 'error', message: "FCM Notification Failed: #{e.message}" }
    end
  end
end