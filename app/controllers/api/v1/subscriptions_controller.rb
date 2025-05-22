class Api::V1::SubscriptionsController < ApplicationController
  before_action :authenticate_user!, except: [:success, :cancel]
  before_action :ensure_supervisor, only: [:index]
  skip_before_action :verify_authenticity_token

  def create
    subscription = @current_user.subscription
    if subscription.stripe_customer_id.blank?
      begin
        customer = Stripe::Customer.create(email: @current_user.email)
        subscription.update!(stripe_customer_id: customer.id)
      rescue StripeError => e
        return render json: { error: 'Failed to create Stripe customer' }, status: :unprocessable_entity
      end
    end
    plan_type = params[:plan_type]
    platform = params[:platform] || 'web'
    return render json: { error: 'Invalid plan type' }, status: :bad_request unless %w[1_day 1_month 3_months].include?(plan_type)
    return render json: { error: 'Invalid platform' }, status: :bad_request unless %w[web mobile].include?(platform)
    price_id = case plan_type
               when '1_day'
                 ENV['ONE_DAY_PRICE_ID']
               when '1_month'
                 ENV['ONE_MONTH_PRICE_ID']
               when '3_months'
                 ENV['THREE_MONTHS_PRICE_ID']
               end

    success_url = if platform == 'web'
                    "#{ENV['WEB_SUCCESS_URL']}?session_id={CHECKOUT_SESSION_ID}"
                  else
                    "#{ENV['MOBILE_SUCCESS_URL']}?session_id={CHECKOUT_SESSION_ID}"
                  end
    
    cancel_url = if platform == 'web'
                    "#{ENV['WEB_CANCEL_URL']}"
                 else
                    "#{ENV['MOBILE_CANCEL_URL']}"
                 end

    session = Stripe::Checkout::Session.create(
      customer: subscription.stripe_customer_id,
      payment_method_types: ['card'],
      line_items: [{ price: price_id, quantity: 1 }],
      mode: 'payment',
      metadata: {
        user_id: @current_user.id,
        plan_type: plan_type,
        platform: platform
      },
      success_url: success_url,
      cancel_url: cancel_url
    )

    render json: { session_id: session.id, url: session.url }, status: :ok
    return
  end
  
  def success
    session = Stripe::Checkout::Session.retrieve(params[:session_id])
    subscription = Subscription.find_by(stripe_customer_id: session.customer)
  
    if subscription
      plan_type = session.metadata.plan_type
      expires_at = case plan_type
        when '1_day'
          1.day.from_now
        when '1_month'
          1.month.from_now
        when '3_months'
          3.months.from_now
        end
      subscription.update(stripe_subscription_id: session.subscription, plan_type: 'premium', status: 'active', expires_at: expires_at)
      platform = session.metadata.platform || 'web'
      message = platform == 'web' ? 'Subscription updated successfully' : 'Subscription confirmed'
      render json: { message: message }, status: :ok
    else
      render json: { error: 'Subscription not found' }, status: :not_found
    end
  end

  def cancel
    render json: { message: 'Payment cancelled' }, status: :ok
  end

  def status
    subscription = @current_user.subscription

    if subscription.nil?
      render json: { error: 'No active subscription found' }, status: :not_found
      return
    end

    if subscription.plan_type == 'premium' && subscription.expires_at.present? && subscription.expires_at < Time.current
      subscription.update(plan_type: 'basic', status: 'active', expires_at: nil)
      render json: { plan_type: 'basic', message: 'Your subscription has expired. Downgrading to basic plan.' }, status: :ok
    else
      render json: { subscription: subscription }, status: :ok
    end
  end

  def index
    subscriptions = Subscription.all
    render json: { subscriptions: subscriptions }, status: :ok
  end
end

