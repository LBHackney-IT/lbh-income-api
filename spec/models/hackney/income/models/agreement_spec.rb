require 'rails_helper'

describe Hackney::Income::Models::Agreement, type: :model do
  let(:user_name) { Faker::Name.name }
  let(:agreement) do
    described_class.create(
      tenancy_ref: '123',
      created_by: user_name,
      agreement_type: :informal
    )
  end

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
      'court_case_id',
      'id'
    )
  end

  it 'can have an associated agreement_state' do
    create(:agreement_state, :live, agreement: agreement)

    expect(described_class.first.agreement_states.first).to be_a Hackney::Income::Models::AgreementState
    expect(Hackney::Income::Models::AgreementState.first.agreement_id).to eq(agreement.id)
  end

  describe 'agreement_type' do
    it 'only accepts formal/informal as an agrement type' do
      %w[formal informal].each do |agreement_type|
        expect { described_class.new(agreement_type: agreement_type) }.not_to raise_error
      end
    end

    it { is_expected.to validate_presence_of(:agreement_type) }

    it 'raises an error when agreement_type is invalid' do
      expect { described_class.new(agreement_type: 'invalid_type') }
        .to raise_error ArgumentError, "'invalid_type' is not a valid agreement_type"
    end
  end

  describe 'frequency' do
    it 'only accepts :weekly/:monthly as frequency' do
      ['weekly', 'monthly', 'fortnightly', '4 weekly'].each do |frequency|
        expect { described_class.new(frequency: frequency) }.not_to raise_error
      end
    end

    it 'raises an error when frequency is invalid' do
      expect { described_class.new(frequency: 'invalid_frequency') }
        .to raise_error ArgumentError, "'invalid_frequency' is not a valid frequency"
    end
  end

  describe 'current_state' do
    it 'returns nil if there are no associated agreement states' do
      expect(agreement.current_state).to be_nil
    end

    it 'returns the latest agreement state' do
      create(:agreement_state, :live, agreement: agreement)
      create(:agreement_state, :breached, agreement: agreement)

      expect(agreement.current_state).to eq('breached')
    end
  end

  describe 'active?' do
    it 'returns false if there are no associated agreement states' do
      expect(agreement.current_state).to be_falsey
    end

    it 'returns true if agreement state is an active state' do
      state = %w[live breached].sample
      create(:agreement_state, agreement_state: state, agreement: agreement)

      expect(agreement.current_state).to eq(state)
      expect(agreement).to be_active
    end

    it 'returns false if agreement is inactive' do
      state = %w[cancelled completed].sample
      create(:agreement_state, agreement_state: state, agreement: agreement)

      expect(agreement.current_state).to eq(state)
      expect(agreement).not_to be_active
    end
  end

  context 'when formal agreement' do
    let(:agreement) do
      described_class.create(
        tenancy_ref: '123',
        created_by: user_name,
        agreement_type: :formal
      )
    end

    it 'validates the presence of court case' do
      expect {
        described_class.create!(
          tenancy_ref: '123',
          created_by: user_name,
          agreement_type: :formal
        )
      }.to raise_error ActiveRecord::RecordInvalid, "Validation failed: Court case can't be blank"
    end
  end
end
