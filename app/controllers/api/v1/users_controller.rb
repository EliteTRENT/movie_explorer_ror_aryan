module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!
      skip_before_action :verify_authenticity_token

      def current
        render json: { id: @current_user.id, email: @current_user.email, role: @current_user.role }
      end

      def update_device_token
        if @current_user.update(device_token: device_token_params[:device_token])
          render json: { message: "Device token updated successfully" }, status: :ok
        else
          render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def toggle_notifications
        if @current_user.update(notifications_enabled: !@current_user.notifications_enabled)
          render json: { message: 'Notifications preference updated', notifications_enabled: @current_user.notifications_enabled }, status: :ok
        else
          render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      private

      def device_token_params
        params.permit(:device_token)
      end
    end
  end
end