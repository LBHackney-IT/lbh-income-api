require 'rails_helper'

describe Hackney::IncomeCollection::Letter::InformalAgreement do
  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:frequency) { 'weekly' }
  let(:amount) { 30 }
  let(:start_date) { Faker::Date.between(from: 2.days.ago, to: Date.today) }
  let(:weekly_rent) { 10.to_f }
  let(:letter_params) {
    {
      tenancy_ref: tenancy_ref,
      payment_ref: Faker::Number.number(digits: 4),
      lessee_full_name: Faker::Name.name,
      correspondence_address1: Faker::Address.street_address,
      correspondence_address2: Faker::Address.secondary_address,
      correspondence_address3: Faker::Address.city,
      correspondence_postcode: Faker::Address.zip_code,
      property_address: Faker::Address.street_address,
      total_collectable_arrears_balance: Faker::Number.number(digits: 3),
      rent: weekly_rent,
      agreement_frequency: frequency,
      amount: amount,
      date_of_first_payment: start_date
    }
  }

  let!(:letter) { described_class.new(letter_params) }

  context 'when the letter is being generated' do
    it 'checks that the template file exists' do
      files = Hackney::IncomeCollection::Letter::InformalAgreement::TEMPLATE_PATHS

      files.each do |file|
        expect(Pathname.new(file)).to exist
      end
    end
  end

  describe '#calculate rent' do
    context 'when the frequency is monthly' do
      let(:frequency) { 'monthly' }

      it 'calculates the correct rent' do
        expect(letter.rent_charge).to eq('43.33')
      end
    end

    context 'when the frequency is fortnightly' do
      let(:frequency) { 'fortnightly' }

      it 'calculates the correct rent' do
        expect(letter.rent_charge).to eq('20.00')
      end
    end

    context 'when the frequency is four weekly' do
      let(:frequency) { '4 weekly' }

      it 'calculates the correct rent' do
        expect(letter.rent_charge).to eq('40.00')
      end
    end

    context 'when the frequency is weekly' do
      it 'calculates the correct rent' do
        expect(letter.rent_charge).to eq('10.00')
      end
    end
  end

  describe '#calculate_total_amount_payable' do
    it 'calculates the correct total amount payable' do
      expect(letter.total_amount_payable).to eq('40.00')
    end
  end
end
