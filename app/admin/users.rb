ActiveAdmin.register User do
  permit_params :name, :email, :password, :mobile_number, :role, :notifications_enabled, :device_token

  index do
    selectable_column
    id_column
    column :name
    column :email
    column :mobile_number
    column :role
    column :notifications_enabled
    column :device_token
    column :created_at
    column :updated_at
    actions
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :email
      f.input :password
      f.input :mobile_number
      f.input :role, as: :select, collection: User.roles.keys
      f.input :notifications_enabled, as: :boolean
      f.input :device_token
    end
    f.actions
  end

  filter :email
  filter :role, as: :select, collection: User.roles.keys
  filter :notifications_enabled, as: :boolean
  filter :device_token, as: :string
  filter :created_at
  filter :updated_at
end