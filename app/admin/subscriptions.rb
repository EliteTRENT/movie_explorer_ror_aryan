ActiveAdmin.register Subscription do
  permit_params :user_id, :plan_type, :status, :created_at, :updated_at, :stripe_customer_id, :stripe_subscription_id, :expires_at

  index do
    selectable_column
    id_column
    column :user_id
    column :plan_type
    column :status
    column :created_at
    column :expires_at
    column :stripe_customer_id
    column :stripe_subscription_id
    actions
  end

  filter :user_id
  filter :plan_type
  filter :status
  filter :created_at
  filter :expires_at

  form do |f|
    f.inputs do
      f.input :user_id, as: :select, collection: User.all.map { |u| [u.email, u.id] }
      f.input :plan_type, as: :select, collection: %w[basic premium] 
      f.input :status, as: :select, collection: %w[active canceled]
      f.input :created_at, as: :datetime_picker
      f.input :expires_at, as: :datetime_picker
      f.input :stripe_customer_id
      f.input :stripe_subscription_id
    end
    f.actions
  end
end