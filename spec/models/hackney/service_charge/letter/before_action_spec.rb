require 'rails_helper'

describe Hackney::ServiceCharge::Letter::BeforeAction do
  let(:letter_params) {
    {
      payment_ref: Faker::Number.number(4),
      lessee_full_name: Faker::Name.name,
      correspondence_address1: Faker::Address.street_address,
      correspondence_address2: Faker::Address.secondary_address,
      correspondence_address3: Faker::Address.city,
      correspondence_postcode: Faker::Address.zip_code,
      property_address: Faker::Address.street_address,
      total_collectable_arrears_balance: Faker::Number.number(3),
      money_judgement: Faker::Number.number(2),
      charging_order: Faker::Number.number(2),
      bal_dispute: Faker::Number.number(2),
      tenure_type: tenure_type,
      original_lease_date: original_lease_date
    }
  }
  let(:tenure_type) { nil }
  let(:original_lease_date) { nil }

  context 'when a money judgement and charging order exists' do
    let(:letter) { described_class.new(letter_params) }

    it 'subtract the money judgement and charging order from the total collectable balance' do
      balance = letter_params[:total_collectable_arrears_balance].to_i
      money_judgement = letter_params[:money_judgement].to_i
      expected_total_collectable_arrears_balance = format('%.2f', balance - money_judgement)
      expect(letter.lba_balance).to eq(expected_total_collectable_arrears_balance)
    end
  end

  describe 'original lease date' do
    let(:letter) { described_class.new(letter_params) }

    context 'when original lease date is nil' do
      it 'is nil' do
        expect(letter.original_lease_date).to be_nil
      end
    end

    context 'when original lease date is valid date' do
      let(:original_lease_date) { Time.zone.now }

      it 'is formatted into a string' do
        expect(letter.original_lease_date).to eq(original_lease_date.strftime('%d %B %Y'))
      end
    end
  end

  describe 'tenure type' do
    let(:letter) { described_class.new(letter_params) }

    context 'with a tenure type of FRS' do
      let(:tenure_type) { Hackney::Income::Domain::TenancyAgreement::TENURE_TYPE_FREEHOLD }

      it 'is not a leasehold' do
        expect(letter.freehold?).to be true
      end
    end

    context 'with a tenure type of LEA' do
      let(:tenure_type) { Hackney::Income::Domain::TenancyAgreement::TENURE_TYPE_LEASEHOLD }

      it 'is a leasehold' do
        expect(letter.freehold?).to be false
      end
    end

    context 'with a tenure type of SHO' do
      let(:tenure_type) { Hackney::Income::Domain::TenancyAgreement::TENURE_TYPE_SHAREDOWNERSHIP }

      it 'is a sharedownership leasehold' do
        expect(letter.freehold?).to be false
      end
    end

    context 'with a tenure type of nil' do
      it 'has not got a tenure type' do
        expect(letter.freehold?).to be false
      end
    end
  end
end
