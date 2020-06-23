require 'rails_helper'

describe Hackney::Income::Models::AgreementState, type: :model do
  it { is_expected.to validate_presence_of(:agreement_id) }
  it { is_expected.to validate_presence_of(:agreement_state) }

  it 'includes the fields for an agreement state' do
    agreement_state = described_class.new

    expect(agreement_state.attributes).to include(
      'agreement_id',
      'agreement_state',
      'created_at',
      'id',
      'updated_at'
    )
  end

  describe 'agreement_state' do
    it 'only accepts valid agreement_states' do
      %w[live breached cancelled completed].each do |agreement_state|
        expect { described_class.new(agreement_state: agreement_state) }.not_to raise_error
      end
    end

    it 'raises an error when agreement_state is invalid' do
      expect { described_class.new(agreement_state: 'invalid_type') }
        .to raise_error ArgumentError, "'invalid_type' is not a valid agreement_state"
    end
  end
end
