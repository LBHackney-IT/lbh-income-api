require 'rails_helper'

describe Hackney::Income::Models::CourtDetails, type: :model do
  it { is_expected.to belong_to(:agreement) }

  it 'includes the fields for a court ordered agreement' do
    court_details = described_class.new
    expect(court_details.attributes).to include(
      'agreement_id',
      'court_decision_date',
      'court_outcome',
      'balance_at_outcome_date'
    )
  end

  it { is_expected.to validate_presence_of(:agreement_id) }
  it { is_expected.to validate_presence_of(:court_decision_date) }
  it { is_expected.to validate_presence_of(:court_outcome) }
  it { is_expected.to validate_presence_of(:balance_at_outcome_date) }
end
