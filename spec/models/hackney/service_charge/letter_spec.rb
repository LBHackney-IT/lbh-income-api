require 'rails_helper'

describe Hackney::ServiceCharge::Letter do
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

  context 'when no errors are present' do
    let(:letter) {
      described_class.build(
        letter_params: letter_params,
        template_path: 'foo'
      )
    }

    it { expect(letter.errors).to eq [] }
  end

  context 'when errors are present' do
    let(:letter) {
      described_class.build(
        letter_params: letter_params.merge(
          payment_ref: '',
          lessee_full_name: '',
          correspondence_address1: '',
          correspondence_address2: '',
          correspondence_address3: '',
          correspondence_postcode: '',
          property_address: '',
          total_collectable_arrears_balance: 0,
          international: true
        ),
        template_path: 'foo'
      )
    }

    it {
      expect(letter.errors).to eq [
        { message: 'missing mandatory field', name: 'payment_ref' },
        { message: 'missing mandatory field', name: 'lessee_full_name' },
        { message: 'missing mandatory field', name: 'correspondence_address1' },
        { message: 'missing mandatory field', name: 'correspondence_address2' },
        { message: 'missing mandatory field', name: 'correspondence_postcode' },
        { message: 'missing mandatory field', name: 'property_address' },
        { message: 'international address', name: 'address' }
      ]
    }
  end

  context 'when reorganisation of the address is needed' do
    let(:letter) {
      described_class.build(
        letter_params: letter_params.merge(correspondence_address1: ''),
        template_path: 'foo'
      )
    }

    it { expect(letter.correspondence_address1).to eq(letter_params[:correspondence_address2]) }

    it { expect(letter.correspondence_address2).to eq(letter_params[:correspondence_address3]) }
  end

  context 'when generating LBA letter' do
    it 'generates an LBA letter' do
      expect(Hackney::ServiceCharge::Letter::BeforeAction).to receive(:new).with(letter_params).and_call_original

      letter = described_class.build(
        letter_params: letter_params,
        template_path: Hackney::ServiceCharge::Letter::BeforeAction::TEMPLATE_PATHS.sample
      )

      expect(letter.errors).to eq [
        { message: 'missing mandatory field', name: 'original_lease_date' },
        { message: 'missing mandatory field', name: 'date_of_current_purchase_assignment' }
      ]
    end

    it 'returns the correct lba balance' do
      letter = described_class.build(
        letter_params: letter_params,
        template_path: Hackney::ServiceCharge::Letter::BeforeAction::TEMPLATE_PATHS.sample
      )
      expected_balance =  format('%.2f',letter_params[:total_collectable_arrears_balance].to_f-letter_params[:money_judgement].to_f)
      expect(letter.lba_balance).to eq(expected_balance.to_s)
    end
  end

  context 'when generating letter two' do
    it 'generates letter 2 letter' do
      expect(Hackney::ServiceCharge::Letter::LetterTwo).to receive(:new).with(letter_params).and_call_original

      letter = described_class.build(
        letter_params: letter_params,
        template_path: Hackney::ServiceCharge::Letter::LetterTwo::TEMPLATE_PATHS.sample
      )

      expect(letter.errors).to eq [
        { message: 'missing mandatory field', name: 'arrears_letter_1_date' }
      ]
    end
  end
end
