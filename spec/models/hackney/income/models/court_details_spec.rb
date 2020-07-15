require 'rails_helper'

describe Hackney::Income::Models::CourtDetails, type: :model do
  it { should belong_to(:agreement) }
  
  it 'includes the fields for a court ordered agreement' do
    court_details = described_class.new
    expect(court_details.attributes).to include(
        'court_decision_date',
        'court_outcome',
        'balance_at_outcome_date',
    ) 
  end


end
