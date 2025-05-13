module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!, except: [:notifications_test]
      skip_before_action :verify_authenticity_token

      def current
        render json: { id: @current_user.id, email: @current_user.email, role: @current_user.role }
      end

      def update_device_token
        device_token = params[:device_token] 
        unless device_token.present?
          render json: { error: 'Device token is required' }, status: :bad_request
          return
        end
        if @current_user.update(device_token: device_token)
          render json: { message: 'Device token updated successfully' }, status: :ok
        else
          render json: { error: 'Failed to update device token', errors: @current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def toggle_notifications
        if @current_user.update(notifications_enabled: !@current_user.notifications_enabled)
          render json: { message: 'Notifications preference updated', notifications_enabled: @current_user.notifications_enabled }, status: :ok
        else
          render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def notifications_test
        users = User.where(notifications_enabled: true).where.not(device_token: nil)
        if users.empty?
          render json: { message: 'No eligible users for notifications' }, status: :ok
          return
        end

        device_tokens = users.pluck(:device_token).map(&:to_s).reject(&:blank?).uniq
        if device_tokens.empty?
          render json: { message: 'No valid device tokens' }, status: :ok
          return
        end

        fcm_service = FcmService.new
        message = params[:message] || 'Test Notification from Movie Explorer'
        begin
          response = fcm_service.send_notification(device_tokens, message, 'This is a test notification.')
          if response[:status_code] == 200
            render json: { message: 'Notification sent successfully', results: response[:body] }, status: :ok
          else
            if response[:invalid_tokens].any?
              User.where(device_token: response[:invalid_tokens]).update_all(device_token: nil)
              Rails.logger.info "Cleared invalid tokens: #{response[:invalid_tokens]}"
            end
            render json: { error: 'Could not send notification to some devices', details: response[:body] }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "FCM Notification Failed: #{e.message}"
          render json: { error: 'FCM Notification Failed', details: e.message }, status: :unprocessable_entity
        end
      end
      
      private

      def device_token_params
        params.permit(:device_token)
      end
    end
  end
end