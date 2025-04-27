class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json
  skip_before_action :verify_authenticity_token
  skip_before_action :require_no_authentication, only: [:create] 
  before_action :log_request

  def create
    build_resource(sign_up_params)
    resource.role = 'user'
    resource.save
    yield resource if block_given?
    if resource.persisted?
      if resource.active_for_authentication?
        sign_up(resource_name, resource)
        render json: {
          id: resource.id,
          email: resource.email,
          role: resource.role,
          token: request.env['warden-jwt_auth.token']
        }, status: :created
      else
        render json: { message: "Signed up but not active" }, status: :ok
      end
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end 
  end

  private

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :name, :mobile_number)
  end
  def log_request
    Rails.logger.info "Headers: #{request.headers.to_h.inspect}"
    Rails.logger.info "CSRF Token: #{request.headers['X-CSRF-Token']}"
    Rails.logger.info "Params: #{params.inspect}"
  end
end