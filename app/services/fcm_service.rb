  require 'httparty'
  require 'googleauth'

  class FcmService
    def initialize
      json_path = ENV['FCM_SERVICE_ACCOUNT_JSON_PATH']
      Rails.logger.info("FCM Service Account JSON Path: #{json_path}")
      raise 'FCM_SERVICE_ACCOUNT_JSON_PATH is not set' if json_path.nil? || json_path.empty?

      normalized_path = File.expand_path(json_path)
      Rails.logger.info("Normalized FCM Service Account JSON Path: #{normalized_path}")

      raise "FCM Service Account JSON file does not exist at #{normalized_path}" unless File.exist?(normalized_path)
      raise "FCM Service Account JSON file is not readable at #{normalized_path}" unless File.readable?(normalized_path)

      # Log the first 100 characters of the JSON file for debugging
      begin
        json_content = File.read(normalized_path)
        Rails.logger.info("Service Account JSON Content (first 100 chars): #{json_content[0..100]}...")
        @credentials = JSON.parse(json_content)
      rescue Errno::ENOENT, Errno::EACCES => e
        raise "Failed to read FCM Service Account JSON file: #{e.message}"
      rescue JSON::ParserError => e
        raise "Invalid FCM Service Account JSON format: #{e.message}"
      end

      # Initialize Google Auth credentials for OAuth2 token generation
      @authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(json_content),
        scope: 'https://www.googleapis.com/auth/firebase.messaging'
      )
      raise 'Failed to initialize Google Auth credentials' if @authorizer.nil?
    end

    def send_notification(device_tokens, title, body, data = {})
      tokens = Array(device_tokens).map(&:to_s).reject do |token|
        if token.strip.empty?
          Rails.logger.warn("Rejected empty FCM token")
          true
        elsif token.include?('test')
          Rails.logger.warn("Rejected FCM token containing 'test': #{token}")
          true
        else
          false
        end
      end

      return { status_code: 200, body: 'No valid device tokens' } if tokens.empty?

      # Fetch OAuth2 access token
      access_token = @authorizer.fetch_access_token!['access_token']
      raise 'Failed to fetch OAuth2 access token' if access_token.nil? || access_token.empty?

      # FCM HTTP v1 API endpoint
      url = "https://fcm.googleapis.com/v1/projects/#{@credentials['project_id']}/messages:send"

      # HTTP v1 API payload structure
      payload = {
        message: {
          notification: {
            title: title.to_s,
            body: body.to_s
          },
          data: data.transform_values(&:to_s)
        }
      }

      headers = {
        'Authorization' => "Bearer #{access_token}",
        'Content-Type' => 'application/json'
      }

      begin
        responses = tokens.map do |token|
          payload[:message][:token] = token
          Rails.logger.info("Sending FCM to token: #{token[0..20]}... with payload: #{payload.inspect}")

          response = HTTParty.post(
            url,
            body: payload.to_json,
            headers: headers
          )

          Rails.logger.info("Raw FCM Response: #{response.inspect}")
          {
            status_code: response.code,
            body: response.body
          }
        end

        status_code = responses.all? { |r| r[:status_code]&.to_i == 200 } ? 200 : 500
        body = responses.map { |r| r[:body] || "No response body" }.join("; ")

        {
          status_code: status_code,
          body: body,
          response: responses
        }
      rescue StandardError => e
        Rails.logger.error("FCM Error: #{e.message}\n#{e.backtrace.join("\n")}")
        { status_code: 500, body: e.message }
      end
    end
  end