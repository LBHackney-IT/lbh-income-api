class CreateAgreements < ActiveRecord::Migration[5.2]
  def change
    create_table :agreements do |t|
      t.string :agreement_type
      t.decimal :starting_balance
      t.decimal :amount
      t.datetime :start_date
      t.integer :frequency
      t.string :current_state

      t.timestamps
    end

    create_table :agreement_states do |t|
      t.belongs_to :agreement
      t.string :agreement_state

      t.timestamps
    end
  end
end
