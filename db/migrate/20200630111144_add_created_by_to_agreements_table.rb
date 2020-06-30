class AddCreatedByToAgreementsTable < ActiveRecord::Migration[5.2]
  def change
    add_column :agreements, :created_by, :string, null: false
  end
end
