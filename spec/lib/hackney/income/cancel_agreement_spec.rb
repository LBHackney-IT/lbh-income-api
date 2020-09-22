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

  let(:cancellation_reason) { Faker::Lorem.characters(number: 40) }
  let(:cancelled_by) { Faker::Name.name.to_s }

  let!(:agreement) { create(:agreement, agreement_params) }
  let(:active_state) { %w[live breached].sample }

  before do
    create(:agreement_state,
           agreement: agreement,
           agreement_state: active_state)
  end

  it 'cancelles an active agreement' do
    cancelled_agreement = subject.execute(
      agreement_id: agreement.id,
      cancelled_by: 'foo',
      cancellation_reason: 'bar'
    )

    expect(cancelled_agreement.id).to eq(agreement.id)
    expect(cancelled_agreement.tenancy_ref).to eq(tenancy_ref)
    expect(cancelled_agreement.current_state).to eq('cancelled')
  end

  it 'creates a new live state with expected balance and description' do
    cancelled_agreement = subject.execute(
      agreement_id: agreement.id,
      cancelled_by: cancelled_by,
      cancellation_reason: cancellation_reason
    )

    new_state = cancelled_agreement.agreement_states.last
    expect(new_state.agreement_state).to eq('cancelled')
    expect(new_state.expected_balance).to eq(nil)
    expect(new_state.checked_balance).to eq(nil)
    expect(new_state.description).to eq("Cancelled by #{cancelled_by}, reason: #{cancellation_reason}")
  end

  context 'when the agreement does not exist' do
    it 'returns nil' do
      non_existent_agreement_id = Faker::Number.number(digits: 10)

      expect(subject.execute(agreement_id: non_existent_agreement_id, cancelled_by: 'foo', cancellation_reason: 'bar')).to be_nil
    end
  end

  context 'when an agreement is completed' do
    before do
      create(:agreement_state,
             :completed,
             agreement: agreement)
    end

    it 'returns the initial agreement' do
      expect(agreement.current_state).to eq('completed')
      expect(agreement.agreement_states.length).to eq(2)

      cancelled_agreement = subject.execute(
        agreement_id: agreement.id,
        cancelled_by: 'foo',
        cancellation_reason: 'bar'
      )

      expect(cancelled_agreement.id).to eq(agreement.id)
      expect(cancelled_agreement.current_state).to eq('completed')
      expect(cancelled_agreement.agreement_states.length).to eq(2)
    end
  end

  context 'when an agreement is already cancelled' do
    before do
      create(:agreement_state,
             :cancelled,
             agreement: agreement)
    end

    it 'returns the initial agreement' do
      expect(agreement.current_state).to eq('cancelled')
      expect(agreement.agreement_states.length).to eq(2)

      cancelled_agreement = subject.execute(
        agreement_id: agreement.id,
        cancelled_by: 'foo',
        cancellation_reason: 'bar'
      )

      expect(cancelled_agreement.id).to eq(agreement.id)
      expect(cancelled_agreement.current_state).to eq('cancelled')
      expect(cancelled_agreement.agreement_states.length).to eq(2)
    end
  end
end
