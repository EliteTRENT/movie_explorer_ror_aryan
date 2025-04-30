class UpdateSubscriptionsFields < ActiveRecord::Migration[7.1]
  def change
    change_column_null :subscriptions, :plan_type, false
    change_column_null :subscriptions, :status, false
    change_column_default :subscriptions, :status, 'active'
  end
end
