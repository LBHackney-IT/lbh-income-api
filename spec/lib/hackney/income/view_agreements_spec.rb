require 'rails_helper'

describe Hackney::Income::ViewAgreements do
  subject { described_class.new.execute(tenancy_ref: tenancy_ref) }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }

  context 'when there are no agreements for the tenancy' do
    it 'returns nothing' do
      expect(subject[:agreements]).to eq([])
    end
  end

  context 'when there is an agreement for the tenancy' do
    let(:agreement_type) { 'formal' }
    let(:starting_balance) { Faker::Commerce.price(range: 10...1000) }
    let(:amount) { Faker::Commerce.price(range: 10...100) }
    let(:start_date) { Faker::Date.between(from: 2.days.ago, to: Date.today) }
    let(:frequency) { 'weekly' }
    let(:current_state) { 'active' }
    let(:agreement_params) do
      {
        tenancy_ref: tenancy_ref,
        agreement_type: agreement_type,
        starting_balance: starting_balance,
        amount: amount,
        start_date: start_date,
        frequency: frequency,
        current_state: current_state
      }
    end

    let!(:expected_agreement) { Hackney::Income::Models::Agreement.create!(agreement_params) }

    it 'returns all agreements with the given tenancy_ref' do
      response = subject

      expect(response[:agreements].count).to eq(1)
      expect(response[:agreements].first[:id]).to eq(expected_agreement.id)
      expect(response[:agreements].first[:tenancyRef]).to eq(tenancy_ref)
      expect(response[:agreements].first[:agreementType]).to eq(agreement_type)
      expect(response[:agreements].first[:startingBalance]).to eq(starting_balance)
      expect(response[:agreements].first[:amount]).to eq(amount)
      expect(response[:agreements].first[:startDate]).to eq(start_date)
      expect(response[:agreements].first[:frequency]).to eq(frequency)
      expect(response[:agreements].first[:currentState]).to eq(nil)
      expect(response[:agreements].first[:history]).to match([])
    end

    it 'correctly maps all agreement_states in history' do
      first_state = Hackney::Income::Models::AgreementState.create!(agreement_id: expected_agreement.id, agreement_state: 'live')
      second_state = Hackney::Income::Models::AgreementState.create!(agreement_id: expected_agreement.id, agreement_state: 'breached')

      response = subject

      expect(response[:agreements].first[:history]).to match([
        {
          state: first_state.agreement_state,
          date: first_state.created_at
        },
        {
          state: second_state.agreement_state,
          date: second_state.created_at
        }
      ])
    end
  end
end
