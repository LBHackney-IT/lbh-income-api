require 'rails_helper'

describe Hackney::Income::CancelAgreement do
  subject { described_class.new }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:agreement_type) { 'informal' }
  let(:amount) { Faker::Commerce.price(range: 10...100) }
  let(:start_date) { Faker::Date.between(from: 2.days.ago, to: Date.today) }
  let(:frequency) { 'weekly' }
  let(:created_by) { Faker::Number.number(digits: 8).to_s }

  let(:agreement_params) do
    {
      tenancy_ref: tenancy_ref,
      agreement_type: agreement_type,
      amount: amount,
      start_date: start_date,
      frequency: frequency,
      created_by: created_by
    }
  end

  let!(:agreement) { Hackney::Income::Models::Agreement.create!(agreement_params) }

  it 'cancelles a given agreement' do
    cancelled_agreement = subject.execute(agreement_id: agreement.id)

    expect(cancelled_agreement.id).to eq(agreement.id)
    expect(cancelled_agreement.tenancy_ref).to eq(tenancy_ref)
    expect(cancelled_agreement.current_state).to eq('cancelled')
  end

  context 'when an agreement already cancelled' do
    before do
      Hackney::Income::Models::AgreementState.create(agreement_id: agreement.id, agreement_state: 'cancelled')
    end

    it 'returns the initial agreement' do
      expect(agreement.current_state).to eq('cancelled')
      expect(agreement.agreement_states.length).to eq(1)

      cancelled_agreement = subject.execute(agreement_id: agreement.id)

      expect(cancelled_agreement.id).to eq(agreement.id)
      expect(cancelled_agreement.current_state).to eq('cancelled')
      expect(cancelled_agreement.agreement_states.length).to eq(1)
    end
  end
end
