class CreateActions < ActiveRecord::Migration[5.2]
  def change
    create_table :actions do |t|
      t.string :tenancy_ref
      t.string :payment_ref
      t.float :balance
      t.string :patch_code
      t.string :classification
      t.string :pause_reason
      t.text :pause_comment
      t.datetime :pause_until
      t.string :action_type
      t.string :service_area_type
      t.text :metadata

      t.timestamps
    end
    add_index :actions, :tenancy_ref, unique: true
  end
end
