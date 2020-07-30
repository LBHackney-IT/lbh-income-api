require 'rails_helper'

describe Hackney::Income::Models::CourtCase, type: :model do
  it 'includes the fields for a court ordered agreement' do
    court_details = described_class.new
    expect(court_details.attributes).to include(
      'tenancy_ref',
      'court_decision_date',
      'court_outcome',
      'balance_at_outcome_date'
    )
  end

  it { is_expected.to validate_presence_of(:tenancy_ref) }
  it { is_expected.to validate_presence_of(:court_decision_date) }
  it { is_expected.to validate_presence_of(:court_outcome) }
  it { is_expected.to validate_presence_of(:balance_at_outcome_date) }
  it { is_expected.to validate_presence_of(:strike_out_date) }
  it { is_expected.to validate_presence_of(:created_by) }
  it { is_expected.to have_many(:agreements) }

  it 'can have associated formal agreements' do
    tenancy_ref = Faker::Number.number(digits: 2).to_s

    court_case = described_class.create!(
      tenancy_ref: tenancy_ref,
      court_decision_date: Faker::Date.between(from: 10.days.ago, to: 3.days.ago),
      court_outcome: Faker::ChuckNorris.fact,
      balance_at_outcome_date: Faker::Commerce.price(range: 10...100),
      strike_out_date: Faker::Date.forward(days: 365),
      created_by: Faker::Name.name
    )

    Hackney::Income::Models::Agreement.create!(
      tenancy_ref: tenancy_ref,
      current_state: :live,
      created_by: Faker::Name.name,
      agreement_type: :formal,
      court_case_id: court_case.id
    )

    expect(described_class.first.agreements.first).to be_a Hackney::Income::Models::Agreement
    expect(Hackney::Income::Models::Agreement.first.court_case).to eq(court_case)
  end
end
