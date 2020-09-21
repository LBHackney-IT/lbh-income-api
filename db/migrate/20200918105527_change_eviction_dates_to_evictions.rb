class ChangeEvictionDatesToEvictions < ActiveRecord::Migration[5.2]
  def up
    change_column_null :eviction_dates, :eviction_date, false
    rename_column :eviction_dates, :eviction_date, :date
    rename_table :eviction_dates, :evictions
  end

  def down
    rename_table :evictions, :eviction_dates
    rename_column :eviction_dates, :date, :eviction_date
    change_column_null :eviction_dates, :eviction_date, true
  end
end
