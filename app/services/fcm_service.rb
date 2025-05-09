require 'httparty'
require 'googleauth'
require 'json'
require 'stringio'

class FcmService
  def initialize
    @credentials = Rails.application.credentials.fcm[:service_account]
    raise 'FCM service account credentials not found' if @credentials.nil?
    json_string = @credentials.to_json
    @authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(json_string),
      scope: 'https://www.googleapis.com/auth/firebase.messaging'
    )
  end

  def send_notification(device_tokens, title, body, data = {})
    tokens = Array(device_tokens).map(&:to_s).reject do |token|
      token.strip.empty? || token.include?('test')
    end

    return { status_code: 200, body: 'No valid device tokens' } if tokens.empty?

    access_token = authorizer.fetch_access_token!['access_token']
    raise 'Failed to fetch access token' if access_token.nil? || access_token.empty?

    url = "https://fcm.googleapis.com/v1/projects/#{@credentials[:project_id]}/messages:send"
    headers = {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/json'
    }

    responses = tokens.map do |token|
      payload = {
        message: {
          token: token,
          notification: {
            title: title.to_s,
            body: body.to_s
          },
          data: data.transform_values(&:to_s)
        }
      }
      response = HTTParty.post(url, body: payload.to_json, headers: headers)
      { status_code: response.code, body: response.body }
    end

    {
      status_code: responses.all? { |r| r[:status_code].to_i == 200 } ? 200 : 500,
      body: responses.map { |r| r[:body] || 'No response body' }.join('; '),
      response: responses
    }
  rescue StandardError => e
    { status_code: 500, body: e.message }
  end

  private

  attr_reader :authorizer
end