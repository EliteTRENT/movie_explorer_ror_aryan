require 'swagger_helper'

RSpec.describe 'User Authentication', type: :request do
  path '/users' do
    post 'User registration' do
      tags 'Authentication'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              name: { type: :string },
              email: { type: :string },
              password: { type: :string },
              password_confirmation: { type: :string },
              mobile_number: { type: :string }
            },
            required: ['name', 'email', 'password', 'password_confirmation', 'mobile_number']
          }
        },
        required: ['user']
      }

      response '201', 'User created successfully' do
        let(:user) { { user: attributes_for(:user) } }
        schema type: :object, properties: {
          id: { type: :integer },
          name: { type: :string },
          email: { type: :string },
          mobile_number: { type: :string }
        }
        run_test!
      end

      response '422', 'Invalid registration request' do
        let(:user) { { user: attributes_for(:user, :invalid) } }
        schema type: :object, properties: { errors: { type: :array, items: { type: :string } } }
        run_test!
      end
    end
  end

  # path '/users/sign_in' do
  #   post 'User login' do
  #     tags 'Authentication'
  #     consumes 'application/json'
  #     produces 'application/json'
  #     parameter name: :user, in: :body, schema: {
  #       type: :object,
  #       properties: {
  #         email: { type: :string },
  #         password: { type: :string }
  #       },
  #       required: ['email', 'password']
  #     }

  #     response '200', 'User logged in successfully' do
  #       let(:user_record) { create(:user) }
  #       let(:user) { { user: { email: user_record.email, password: 'password123' } } }
  #       run_test!
  #     end

  #     response '401', 'Unauthorized login attempt' do
  #       let(:user) { { user: { email: 'wrong@example.com', password: 'wrongpass' } } }
  #       run_test!
  #     end
  #   end
  # end

  # path '/users/sign_out' do
  #   delete 'User logout' do
  #     tags 'Authentication'
  #     produces 'application/json'
  #     security [BearerAuth: []]

  #     response '204', 'User logged out successfully' do
  #       let(:user_record) { create(:user) }
  #       let(:Authorization) { "Bearer #{JWT.encode({ jti: user_record.jti }, Rails.application.secrets.secret_key_base)}" }
  #       run_test!
  #     end

  #     response '401', 'Unauthorized logout attempt' do
  #       let(:Authorization) { nil }
  #       run_test!
  #     end
  #   end
  # end
end