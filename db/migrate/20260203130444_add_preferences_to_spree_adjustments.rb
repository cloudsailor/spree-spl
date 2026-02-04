class AddPreferencesToSpreeAdjustments < ActiveRecord::Migration[8.1]
  def change
    add_column :spree_adjustments, :preferences, :text
  end
end
