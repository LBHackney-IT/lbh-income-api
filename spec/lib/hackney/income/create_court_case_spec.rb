require 'rails_helper'

describe Hackney::Income::CreateCourtCase do
  subject { described_class.new }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:court_date) { Faker::Date.between(from: 10.days.ago, to: 2.days.ago) }
  let(:court_outcome) { Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_ON_TERMS }
  let(:balance_on_court_outcome_date) { Faker::Commerce.price(range: 10...100) }
  let(:strike_out_date) { Faker::Date.forward(days: 365) }
  let(:terms) { [true, false].sample }
  let(:disrepair_counter_claim) { [true, false].sample }

  let(:new_court_case_params) do
    {
      tenancy_ref: tenancy_ref,
      court_date: court_date,
      court_outcome: court_outcome,
      balance_on_court_outcome_date: balance_on_court_outcome_date,
      strike_out_date: strike_out_date,
      terms: terms,
      disrepair_counter_claim: disrepair_counter_claim
    }
  end

  it 'creates and returns a new court case' do
    court_case = subject.execute(court_case_params: new_court_case_params)

    latest_court_case_id = Hackney::Income::Models::CourtCase.where(tenancy_ref: tenancy_ref).last.id
    expect(court_case).to be_an_instance_of(Hackney::Income::Models::CourtCase)
    expect(court_case.id).to eq(latest_court_case_id)
    expect(court_case.tenancy_ref).to eq(tenancy_ref)
    expect(court_case.court_date).to eq(court_date)
    expect(court_case.court_outcome).to eq(court_outcome)
    expect(court_case.balance_on_court_outcome_date).to eq(balance_on_court_outcome_date)
    expect(court_case.strike_out_date).to eq(strike_out_date)
    expect(court_case.terms).to eq(terms)
    expect(court_case.disrepair_counter_claim).to eq(disrepair_counter_claim)
  end
end
