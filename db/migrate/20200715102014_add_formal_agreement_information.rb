class AddFormalAgreementInformation < ActiveRecord::Migration[5.2]
  def change
    create_table :court_details do |t|
      t.belongs_to :agreement
      t.datetime :court_decision_date
      t.text :court_outcome
      t.decimal :balance_at_outcome_date
      
      t.timestamps
    end
  end
end
