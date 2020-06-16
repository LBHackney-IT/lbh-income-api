require 'rails_helper'

describe Hackney::Income::Models::Agreement, type: :model do
  it 'includes the fields for a formal/informal agreement' do
    agreement = described_class.new

    expect(agreement.attributes).to include(
      'agreement_type',
      'starting_balance',
      'amount',
      'frequency',
      'current_state',
      'start_date',
      'created_at',
      'updated_at',
      'tenancy_ref',
      'id'
    )
  end

  it 'has an associated agreement_state' do
    agreement = described_class.create(tenancy_ref: '123')
    Hackney::Income::Models::AgreementState.create(agreement_id: agreement.id)

    expect(described_class.first.agreement_states.first).to be_a Hackney::Income::Models::AgreementState
    expect(Hackney::Income::Models::AgreementState.first.agreement_id).to eq(agreement.id)
  end

  describe 'agreement_type' do
    it 'only accepts formal/informal as an agrement type' do
      %w[formal informal].each do |agreement_type|
        expect { described_class.new(agreement_type: agreement_type) }.not_to raise_error
      end
    end

    it 'raises an error when agreement_type is invalid' do
      expect { described_class.new(agreement_type: 'invalid_type') }
        .to raise_error ArgumentError, "'invalid_type' is not a valid agreement_type"
    end
  end

  describe 'frequency' do
    it 'only accepts :weekly/:monthly as frequency' do
      %i[weekly monthly].each do |frequency|
        expect { described_class.new(frequency: frequency) }.not_to raise_error
      end
    end

    it 'raises an error when frequency is invalid' do
      expect { described_class.new(frequency: 'invalid_frequency') }
        .to raise_error ArgumentError, "'invalid_frequency' is not a valid frequency"
    end
  end
end
