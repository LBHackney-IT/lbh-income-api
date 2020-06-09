class AddTenancyRefToAgreementsTable < ActiveRecord::Migration[5.2]
  def change
    add_column :agreements, :tenancy_ref, :string, null: false
  end
end
