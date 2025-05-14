require 'rails_helper'

RSpec.describe 'API V1 Users', type: :request do
  let(:user) { create(:user) }
  let(:supervisor) { create(:user, :supervisor) }
  let(:jwt_token) { "mocked_jwt_token_#{user.id}" }
  let(:supervisor_token) { "mocked_jwt_token_#{supervisor.id}" }
  let(:headers) { { 'Authorization' => "Bearer #{jwt_token}" } }
  let(:supervisor_headers) { { 'Authorization' => "Bearer #{supervisor_token}" } }
  let(:invalid_headers) { { 'Authorization' => 'Bearer invalid_token' } }
  let(:decoded_token) { [{ 'sub' => user.id, 'jti' => user.jti }, { 'alg' => 'HS256' }] }
  let(:supervisor_decoded_token) { [{ 'sub' => supervisor.id, 'jti' => supervisor.jti }, { 'alg' => 'HS256' }] }

  before do
    allow(JWT).to receive(:decode).with(jwt_token, anything, true, { algorithm: 'HS256' }).and_return(decoded_token)
    allow(JWT).to receive(:decode).with(supervisor_token, anything, true, { algorithm: 'HS256' }).and_return(supervisor_decoded_token)
    allow(JWT).to receive(:decode).with('invalid_token', anything, true, hash_including(algorithm: 'HS256')).and_raise(JWT::DecodeError, 'Invalid or expired token')
    allow(JwtBlacklist).to receive(:exists?).and_return(false)
  end

  describe 'POST /users (Registration)' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          user: {
            name: 'John Doe',
            email: 'john@example.com',
            password: 'Password@123',
            mobile_number: '+12345678901'
          }
        }
      end

      it 'creates a new user and returns status 201' do
        post '/users', params: valid_attributes, as: :json
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['email']).to eq('john@example.com')
        expect(json['role']).to eq('user')
        expect(json['token']).to be_present
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) do
        {
          user: {
            name: '',
            email: 'invalid',
            password: '',
            mobile_number: ''
          }
        }
      end

      it 'returns status 422 with errors' do
        post '/users', params: invalid_attributes, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include(/Name can't be blank/, /Email is invalid/, /Password can't be blank/, /Mobile number is invalid/)
      end
    end
  end

  describe 'POST /users/sign_in (Login)' do
    let!(:user_record) { create(:user, password: 'Password@123') }

    context 'with correct credentials' do
      let(:valid_credentials) do
        {
          user: {
            email: user_record.email,
            password: 'password123'
          }
        }
      end

      it 'logs in the user and returns a token' do
        allow_any_instance_of(Warden::Proxy).to receive(:authenticate!).and_return(user_record)
        allow_any_instance_of(Warden::Proxy).to receive(:authenticated?).and_return(false)

        post '/users/sign_in', params: valid_credentials, as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['email']).to eq(user_record.email)
        expect(json['token']).to be_present
      end
    end
  end

  describe 'DELETE /users/sign_out (Logout)' do
    context 'with no token' do
      it 'returns unauthorized status' do
        delete '/users/sign_out', as: :json
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('No token provided. Please include a valid Bearer token.')
      end
    end
  end

  describe 'GET /api/v1/current_user' do
    context 'when user is signed in' do
      it 'returns the current user with status 200' do
        get '/api/v1/current_user', headers: headers, as: :json
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['id']).to eq(user.id)
        expect(data['email']).to eq(user.email)
        expect(data['role']).to eq('user')
      end

      it 'returns the current supervisor with status 200' do
        get '/api/v1/current_user', headers: supervisor_headers, as: :json
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['id']).to eq(supervisor.id)
        expect(data['email']).to eq(supervisor.email)
        expect(data['role']).to eq('supervisor')
      end
    end

    context 'when user is not signed in' do
      it 'returns unauthorized status' do
        get '/api/v1/current_user', headers: invalid_headers, as: :json
        expect(response).to have_http_status(:unauthorized)
        data = JSON.parse(response.body)
        expect(data['error']).to include('Invalid or expired token')
      end
    end
  end

  describe 'POST /api/v1/update_device_token' do
  context 'with valid parameters' do
    let(:valid_params) { { device_token: 'abc123' } }

    it 'updates the device token for a user and returns status 200' do
      post '/api/v1/update_device_token', params: valid_params, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(user.reload.device_token).to eq('abc123')
    end

    it 'updates the device token for a supervisor and returns status 200' do
      post '/api/v1/update_device_token', params: valid_params, headers: supervisor_headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(supervisor.reload.device_token).to eq('abc123')
    end
  end

  context 'with invalid parameters' do
    let(:invalid_params) { { device_token: '' } }

    it 'returns bad request status with error message' do
      post '/api/v1/update_device_token', params: invalid_params, headers: headers, as: :json
      expect(response).to have_http_status(:bad_request)
      data = JSON.parse(response.body)
      expect(data['error']).to eq('Device token is required')
    end
  end

  context 'when user is not signed in' do
    let(:valid_params) { { device_token: 'abc123' } }

    it 'returns unauthorized status' do
      post '/api/v1/update_device_token', params: valid_params, headers: invalid_headers, as: :json
      expect(response).to have_http_status(:unauthorized)
      data = JSON.parse(response.body)
      expect(data['error']).to include('Invalid or expired token')
    end
  end
end

  describe 'PATCH /api/v1/toggle_notifications' do
    context 'when user is signed in' do
      it 'toggles notifications from false to true for a user and returns status 200' do
        patch '/api/v1/toggle_notifications', headers: headers, as: :json
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['notifications_enabled']).to eq(false)
        expect(user.reload.notifications_enabled).to eq(false)
      end

      it 'toggles notifications from false to true for a supervisor and returns status 200' do
        patch '/api/v1/toggle_notifications', headers: supervisor_headers, as: :json
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['notifications_enabled']).to eq(false)
        expect(supervisor.reload.notifications_enabled).to eq(false)
      end

      it 'toggles notifications from true to false for a user and returns status 200' do
        user.update!(notifications_enabled: true)
        patch '/api/v1/toggle_notifications', headers: headers, as: :json
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['notifications_enabled']).to eq(false)
        expect(user.reload.notifications_enabled).to eq(false)
      end
    end

    context 'when user is not signed in' do
      it 'returns unauthorized status' do
        patch '/api/v1/toggle_notifications', headers: invalid_headers, as: :json
        expect(response).to have_http_status(:unauthorized)
        data = JSON.parse(response.body)
        expect(data['error']).to include('Invalid or expired token')
      end
    end
  end
end