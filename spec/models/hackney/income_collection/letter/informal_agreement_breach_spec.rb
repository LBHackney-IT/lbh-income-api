require 'rails_helper'

describe Hackney::IncomeCollection::Letter::InformalAgreementBreach do
  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:created_date) { Faker::Date.between(from: 2.days.ago, to: Date.today) }
  let(:expected_balance) { 60 }
  let(:checked_balance) { 70 }
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
      created_date: created_date,
      expected_balance: expected_balance,
      checked_balance: checked_balance
    }
  }

  let!(:letter) { described_class.new(letter_params) }

  context 'when the letter is being generated' do
    it 'checks that the template file exists' do
      files = Hackney::IncomeCollection::Letter::InformalAgreementBreach::TEMPLATE_PATHS

      files.each do |file|
        expect(Pathname.new(file)).to exist
      end
    end
  end

  context 'when calculating the shortfall amount' do
    it 'calculates the correct amount' do
      expect(letter.shortfall_amount).to eq('10.00')
    end
  end
end
