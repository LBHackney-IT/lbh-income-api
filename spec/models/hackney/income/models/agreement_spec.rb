require 'rails_helper'

describe Hackney::Income::Models::Agreement, type: :model do
  let(:user_name) { Faker::Name.name }

  it 'includes the fields for a formal/informal agreement' do
    agreement = described_class.new

    expect(agreement.attributes).to include(
      'agreement_type',
      'starting_balance',
      'amount',
      'frequency',
      'current_state',
      'start_date',
      'created_by',
      'created_at',
      'updated_at',
      'tenancy_ref',
      'notes',
      'id'
    )
  end

  it 'can have an associated agreement_state' do
    agreement = described_class.create(tenancy_ref: '123', created_by: user_name)
    Hackney::Income::Models::AgreementState.create(agreement_id: agreement.id, agreement_state: 'live')

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

  describe 'current_state' do
    let(:agreement) { described_class.create(tenancy_ref: '123', created_by: user_name) }

    it 'returns nil if there are no associated agreement states' do
      expect(agreement.current_state).to be_nil
    end

    it 'returns the latest agreement state' do
      Hackney::Income::Models::AgreementState.create(agreement_id: agreement.id, agreement_state: 'live')
      Hackney::Income::Models::AgreementState.create(agreement_id: agreement.id, agreement_state: 'breached')

      expect(agreement.current_state).to eq('breached')
    end
  end

  describe 'active?' do
    let(:agreement) { described_class.create(tenancy_ref: '123', created_by: user_name) }

    it 'returns false if there are no associated agreement states' do
      expect(agreement.current_state).to be_falsey
    end

    it 'returns true if agreement state is an active state' do
      state = %w[live breached].sample
      Hackney::Income::Models::AgreementState.create(agreement_id: agreement.id, agreement_state: state)

      expect(agreement.current_state).to eq(state)
      expect(agreement).to be_active
    end

    it 'returns false if agreement is inactive' do
      state = %w[cancelled completed].sample
      Hackney::Income::Models::AgreementState.create(agreement_id: agreement.id, agreement_state: state)

      expect(agreement.current_state).to eq(state)
      expect(agreement).not_to be_active
    end
  end
end
