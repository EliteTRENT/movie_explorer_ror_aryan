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
    tokens = Array(device_tokens).map(&:to_s).reject { |token| token.strip.empty? }
    return { status_code: 200, body: [{ message: 'No valid device tokens' }], tokens: [] } if tokens.empty?

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
          data: data.merge(banner_url: data[:banner_url]&.to_s).transform_values(&:to_s)
        }
      }
      response = HTTParty.post(url, body: payload.to_json, headers: headers)
      parsed_body = parse_response(response)
      {
        token: token,
        status_code: response.code,
        body: parsed_body
      }
    end

    invalid_tokens = responses.select { |r| r[:body]['error']&.dig('code') == 400 }.map { |r| r[:token] }

    {
      status_code: responses.all? { |r| r[:status_code] == 200 } ? 200 : (invalid_tokens.any? ? 400 : 500),
      body: responses,
      invalid_tokens: invalid_tokens
    }
  rescue StandardError => e
    { status_code: 500, body: [{ error: e.message }], invalid_tokens: [] }
  end

  private

  def parse_response(response)
    return { error: 'No response body' } unless response.body
    JSON.parse(response.body)
  rescue JSON::ParserError
    { error: response.body }
  end

  attr_reader :authorizer
end