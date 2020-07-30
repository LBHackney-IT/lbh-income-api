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

  let!(:agreement) { create(:agreement, agreement_params) }
  let(:active_state) { %w[live breached].sample }

  before do
    create(:agreement_state,
           agreement_id: agreement.id,
           agreement_state: active_state)
  end

  it 'cancelles an active agreement' do
    cancelled_agreement = subject.execute(agreement_id: agreement.id)

    expect(cancelled_agreement.id).to eq(agreement.id)
    expect(cancelled_agreement.tenancy_ref).to eq(tenancy_ref)
    expect(cancelled_agreement.current_state).to eq('cancelled')
  end

  context 'when the agreement does not exist' do
    it 'returns nil' do
      non_existent_agreement_id = Faker::Number.number(digits: 10)

      expect(subject.execute(agreement_id: non_existent_agreement_id)).to be_nil
    end
  end

  context 'when an agreement is completed' do
    before do
      create(:agreement_state,
             :completed,
             agreement_id: agreement.id)
    end

    it 'returns the initial agreement' do
      expect(agreement.current_state).to eq('completed')
      expect(agreement.agreement_states.length).to eq(2)

      cancelled_agreement = subject.execute(agreement_id: agreement.id)

      expect(cancelled_agreement.id).to eq(agreement.id)
      expect(cancelled_agreement.current_state).to eq('completed')
      expect(cancelled_agreement.agreement_states.length).to eq(2)
    end
  end

  context 'when an agreement is already cancelled' do
    before do
      create(:agreement_state,
             :cancelled,
             agreement_id: agreement.id)
    end

    it 'returns the initial agreement' do
      expect(agreement.current_state).to eq('cancelled')
      expect(agreement.agreement_states.length).to eq(2)

      cancelled_agreement = subject.execute(agreement_id: agreement.id)

      expect(cancelled_agreement.id).to eq(agreement.id)
      expect(cancelled_agreement.current_state).to eq('cancelled')
      expect(cancelled_agreement.agreement_states.length).to eq(2)
    end
  end
end
