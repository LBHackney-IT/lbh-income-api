require 'rails_helper'

describe Hackney::Income::CreateAgreement do
  subject { described_class.new }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:agreement_type) { 'informal' }
  let(:amount) { Faker::Commerce.price(range: 10...100) }
  let(:start_date) { Faker::Date.between(from: 2.days.ago, to: Date.today) }
  let(:frequency) { 'weekly' }

  let(:existing_agreement_params) do
    {
      tenancy_ref: tenancy_ref,
      agreement_type: 'formal',
      amount: Faker::Commerce.price(range: 10...100),
      start_date: Faker::Date.between(from: 4.days.ago, to: Date.today),
      frequency: frequency
    }
  end

  let(:new_agreement_params) do
    {
      tenancy_ref: tenancy_ref,
      agreement_type: agreement_type,
      amount: amount,
      start_date: start_date,
      frequency: frequency
    }
  end

  context 'when there are no previous agreements for the tenancy' do
    it 'creates and returns a new live agreement' do
      Hackney::Income::Models::CasePriority.create!(tenancy_ref: tenancy_ref, balance: 100)

      response = subject.execute(new_agreement_params: new_agreement_params)

      expect(response[:tenancyRef]).to eq(tenancy_ref)
      expect(response[:agreementType]).to eq(agreement_type)
      expect(response[:amount]).to eq(amount)
      expect(response[:startDate]).to eq(start_date)
      expect(response[:frequency]).to eq(frequency)
      expect(response[:currentState]).to eq('live')
      expect(response[:history].count).to eq(1)
      expect(response[:history].first[:state]).to eq('live')
      expect(response[:startingBalance]).to eq(100)
    end
  end

  context 'when there is a previous agreement for the tenancy' do
    it "creates and returns a new live agreement and the previous agreement's state is set to 'cancelled' " do
      Hackney::Income::Models::CasePriority.create!(tenancy_ref: tenancy_ref, balance: 200)

      existing_agreement = subject.execute(new_agreement_params: existing_agreement_params)
      new_agreement = subject.execute(new_agreement_params: new_agreement_params)

      agreements = Hackney::Income::Models::Agreement.where(tenancy_ref: tenancy_ref).includes(:agreement_states)

      expect(agreements.count).to eq(2)

      expect(agreements.first.tenancy_ref).to eq(existing_agreement[:tenancyRef])
      expect(agreements.second.tenancy_ref).to eq(new_agreement[:tenancyRef])
      expect(agreements.first.current_state).to eq('cancelled')
    end
  end
end
