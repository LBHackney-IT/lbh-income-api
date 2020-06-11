require 'rails_helper'

describe Hackney::Income::CreateAgreement do
  subject { described_class.execute(new_agreement_params: new_agreement_params) }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:agreement_type) { 'informal' }
  let(:amount) { Faker::Commerce.price(range: 10...100) }
  let(:start_date) { Faker::Date.between(from: 2.days.ago, to: Date.today) }
  let(:frequency) { 'weekly' }


  # let(:existing_agreement_params) do
  #   {
  #     tenancy_ref: tenancy_ref.to_s,
  #     agreement_type: 'formal',
  #     amount: 5.to_s,
  #     start_date: Faker::Date.between(from: 4.days.ago, to: Date.today).to_s,
  #     frequency: frequency,
  #     current_state: 'breached'
  #   }
  # end


  # let(:existing_agreement_params) do
  #   {
  #     tenancy_ref: tenancy_ref.to_s,
  #     agreement_type: 'formal',
  #     amount: 5.to_s,
  #     start_date: Faker::Date.between(from: 4.days.ago, to: Date.today).to_s,
  #     frequency: frequency,
  #     current_state: 'breached'
  #   }
  # end

  # Would the parameters be passed to the use case as strings??
  let(:new_agreement_params) do
    {
      tenancy_ref: tenancy_ref.to_s,
      agreement_type: agreement_type,
      amount: amount.to_s,
      start_date: start_date.to_s,
      frequency: frequency
    }
  end

  context 'when there are no previous agreements for the tenancy' do
    it 'creates and returns a new active agreement with the new agreement in its history' do
      Hackney::Income::Models::CasePriority.create!(tenancy_ref: tenancy_ref, balance: 100)

      expect(subject[:tenancyRef]).to eq(tenancy_ref)
      expect(subject[:agreementType]).to eq(agreement_type)
      expect(subject[:amount]).to eq(amount)
      expect(subject[:startDate]).to eq(start_date)
      expect(subject[:frequency]).to eq(frequency)
      expect(subject[:currentState]).to eq('active')
      expect(subject[:history].count).to eq(1)
      expect(subject[:history].first[:state]).to eq('active')
      expect(subject[:startingBalance]).to eq(100)
    end
  end
  # I spent way too long being confused because I thought the history was meant to show the  agreements
  # for a tenancy ref - the I realised, it's the different states one agreement has been in
  # Although are we doing new agreements for one tenancy_ref as different agreements?
  #
  # context 'when there is a previous agreement for the tenancy' do
  #   it 'creates and returns a new active agreement with the two agreements in history' do
  #     Hackney::Income::Models::CasePriority.create!(tenancy_ref: tenancy_ref, balance: 200)
  #
  #     existing_agreement = described_class.execute(new_agreement_params: existing_agreement_params)
  #     existing_agreement2 = described_class.execute(new_agreement_params: existing_agreement2_params)
  #
  #     expect(subject[:tenancyRef]).to eq(tenancy_ref)
  #     expect(subject[:agreementType]).to eq(agreement_type)
  #     expect(subject[:amount]).to eq(amount)
  #     expect(subject[:startDate]).to eq(start_date)
  #     expect(subject[:frequency]).to eq(frequency)
  #     expect(subject[:currentState]).to eq('active')
  #
  #     expect(subject[:history].count).to eq(2)
  #     expect(subject[:history].first[:state]).to eq('breached')
  #     expect(subject[:startingBalance]).to eq(200)
  #   end
  # end
end
