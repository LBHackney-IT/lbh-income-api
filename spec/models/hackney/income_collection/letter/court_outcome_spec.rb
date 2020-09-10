require 'rails_helper'

describe Hackney::IncomeCollection::Letter::CourtOutcome do
  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:created_date) { Faker::Date.between(from: 2.days.ago, to: Date.today) }
  let(:court_outcome) { Hackney::Tenancy::UpdatedCourtOutcomeCodes::WITHDRAWN_ON_THE_DAY }
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
      court_outcome: court_outcome
    }
  }

  let!(:letter) { described_class.new(letter_params) }

  context 'when the letter is being generated' do
    it 'checks that the template file exists' do
      files = Hackney::IncomeCollection::Letter::CourtOutcome::TEMPLATE_PATHS

      files.each do |file|
        expect(Pathname.new(file)).to exist
      end
    end
  end

  context '#formal_agreement?' do

  end
end
