class AddNotificationsEnabledToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :notifications_enabled, :boolean, default: false, null: false
  end
end
