class CreateAgreements < ActiveRecord::Migration[5.2]
  def change
    create_table :agreements do |t|
      t.string :agreement_type
      t.decimal :starting_balance
      t.decimal :amount
      t.integer :number_of_payments
      t.datetime :start_date
      t.integer :frequency

      t.timestamps
    end
  end
end
