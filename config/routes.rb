Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users, controllers: { sessions: 'users/sessions', registrations: "users/registrations" }
  namespace :api do
    namespace :v1 do
      get 'current_user' => 'users#current'
      post 'update_device_token' => 'users#update_device_token'
      patch 'toggle_notifications' => 'users#toggle_notifications'
      post 'notifications/test' => 'users#notifications_test'
      resources :movies, only: [:index, :show, :create, :update, :destroy]
      resources :subscriptions, only: [:create, :index]
      get 'subscriptions/status', to: 'subscriptions#status'
      get 'subscriptions/success', to: 'subscriptions#success'
      get 'subscriptions/cancel', to: 'subscriptions#cancel'
    end
  end
end