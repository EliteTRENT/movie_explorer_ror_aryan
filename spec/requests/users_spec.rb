require 'rails_helper'

RSpec.describe "User Authentication with JWT", type: :request do
  let(:password) { 'Password@123' }
  let(:user) { create(:user, password: password) }  

  def auth_token_for_user(user)
    post '/users/sign_in', params: { user: { email: user.email, password: password } }, as: :json
    expect(response).to have_http_status(:ok)
    response.headers['Authorization']
  end

  describe 'POST /users (Sign up)' do
    let(:new_user) { build(:user, password: password, mobile_number: '1234567890', notifications_enabled: true) }
  
    it 'registers a new user and returns JWT token' do
      post '/users', params: { user: new_user.attributes.merge(password: password) }, as: :json

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
  
      expect(json['email']).to eq(new_user.email)
      expect(json['token']).to be_present
    end
  end
  

  describe 'DELETE /users/sign_out (Sign out)' do
    it 'logs out an authenticated user' do
      token = auth_token_for_user(user)

      delete '/users/sign_out', headers: { 'Authorization' => token }, as: :json

      expect(response).to have_http_status(:ok)
    end

    it 'rejects logout without token' do
      delete '/users/sign_out', as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to match(/No token provided/)
    end
  end

  describe 'GET /api/v1/current_user' do
    it 'returns the current authenticated user' do
      token = auth_token_for_user(user)

      get '/api/v1/current_user', headers: { 'Authorization' => token }, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['email']).to eq(user.email)
    end

    it 'rejects request without token' do
      get '/api/v1/current_user', as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to match(/No token provided/)
    end
  end
end
