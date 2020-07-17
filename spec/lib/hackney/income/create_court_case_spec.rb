require 'rails_helper'

describe Hackney::Income::CreateCourtCase do
  subject { described_class.new }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:court_decision_date) { Faker::Date.between(from: 10.days.ago, to: 2.days.ago) }
  let(:court_outcome) { Faker::ChuckNorris.fact }
  let(:balance_at_outcome_date) { Faker::Commerce.price(range: 10...100) }

  let(:new_court_case_params) do
    {
      tenancy_ref: tenancy_ref,
      court_decision_date: court_decision_date,
      court_outcome: court_outcome,
      balance_at_outcome_date: balance_at_outcome_date
    }
  end

  it 'creates and returns a new court case' do
    court_case = subject.execute(court_case_params: new_court_case_params)

    latest_court_case_id = Hackney::Income::Models::CourtCase.where(tenancy_ref: tenancy_ref).last.id
    expect(court_case).to be_an_instance_of(Hackney::Income::Models::CourtCase)
    expect(court_case.id).to eq(latest_court_case_id)
    expect(court_case.tenancy_ref).to eq(tenancy_ref)
    expect(court_case.court_decision_date).to eq(court_decision_date)
    expect(court_case.court_outcome).to eq(court_outcome)
    expect(court_case.balance_at_outcome_date).to eq(balance_at_outcome_date)
  end
end
