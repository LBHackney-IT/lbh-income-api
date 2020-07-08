class CreateLeaseholdCaseAttributes < ActiveRecord::Migration[5.2]
  def change
    create_table :leasehold_case_attributes do |t|
      t.string :payment_ref
      t.string :tenancy_ref
      t.string :patch
      t.float :balance
      t.text :property_address
      t.string :lessee
      t.string :tenure_type
      t.string :direct_debit_status
      t.string :latest_letter
      t.string :latest_letter_date
      t.datetime :is_paused_until
      t.string :pause_reason
      t.text :pause_comment

      t.timestamps
    end
    add_index :leasehold_case_attributes, :tenancy_ref
  end
end
