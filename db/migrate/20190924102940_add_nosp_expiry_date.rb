class AddNospExpiryDate < ActiveRecord::Migration[5.2]
  def change
    add_column :case_priorities, :nosp_expiry_date, :date
  end
end
