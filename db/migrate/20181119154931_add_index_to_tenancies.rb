class AddIndexToTenancies < ActiveRecord::Migration[5.1]
  def change
    add_index :tenancies, :tenancy_ref, unique: true
  end
end
