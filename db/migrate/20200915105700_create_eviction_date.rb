class CreateEvictionDate < ActiveRecord::Migration[5.2]
  def change
    create_table :eviction_dates do |t|
      t.datetime :eviction_date
      t.string :tenancy_ref, null: false

      t.timestamps
    end
  end
end
