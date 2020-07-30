require 'rails_helper'

describe Hackney::Income::ViewAgreements do
  subject { described_class.new.execute(tenancy_ref: tenancy_ref) }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }

  context 'when there are no agreements for the tenancy' do
    it 'returns an empty array' do
      expect(subject).to eq([])
    end
  end

  context 'when there is an agreement for the tenancy' do
    let(:agreement_type) { 'informal' }
    let(:starting_balance) { Faker::Commerce.price(range: 10...1000) }
    let(:amount) { Faker::Commerce.price(range: 10...100) }
    let(:start_date) { Faker::Date.between(from: 2.days.ago, to: Date.today) }
    let(:frequency) { 'weekly' }
    let(:current_state) { 'live' }
    let(:created_by) { Faker::Name.name }
    let(:agreement_params) do
      {
        tenancy_ref: tenancy_ref,
        agreement_type: agreement_type,
        starting_balance: starting_balance,
        amount: amount,
        start_date: start_date,
        frequency: frequency,
        current_state: current_state,
        created_by: created_by
      }
    end

    let!(:expected_agreement) { create(:agreement, agreement_params) }

    it 'returns all agreements with the given tenancy_ref' do
      response = subject

      expect(response.count).to eq(1)
      expect(response.first.id).to eq(expected_agreement.id)
      expect(response.first.tenancy_ref).to eq(tenancy_ref)
      expect(response.first.agreement_type).to eq(agreement_type)
      expect(response.first.starting_balance).to eq(starting_balance)
      expect(response.first.amount).to eq(amount)
      expect(response.first.start_date).to eq(start_date)
      expect(response.first.frequency).to eq(frequency)
      expect(response.first.created_by).to eq(created_by)
      expect(response.first.current_state).to eq(nil)
    end
  end
end
