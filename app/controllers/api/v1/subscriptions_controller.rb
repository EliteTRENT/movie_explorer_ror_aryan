class Api::V1::SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def create
    subscription = Subscription.create!(user: current_user, plan_type: params[:plan_type], status: 'active')
    render json: { message: 'Subscription created successfully.', subscription: subscription }, status: :created
  rescue ArgumentError
      render json: { error: 'Invalid plan selected.' }, status: :unprocessable_entity
  end

  def index
    subscriptions = current_user.subscriptions
    render json: { subscriptions: subscriptions }, status: :ok
  end

  def show
    render json: { subscription: @subscription }, status: :ok
  end
end
