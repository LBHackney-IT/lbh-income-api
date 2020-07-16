class AddFormalAgreementInformation < ActiveRecord::Migration[5.2]
  def change
    create_table :court_details do |t|
      t.belongs_to :agreement
      t.datetime :court_decision_date, null: false
      t.text :court_outcome, null: false
      t.decimal :balance_at_outcome_date, null: false

      t.timestamps
    end
  end
end
