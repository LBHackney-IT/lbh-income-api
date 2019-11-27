require 'rails_helper'

describe Hackney::ServiceCharge::Letter::LetterTwo do
  let(:letter_params) {
    {
      payment_ref: Faker::Number.number(4),
      lessee_full_name: Faker::Name.name,
      correspondence_address1: Faker::Address.street_address,
      correspondence_address2: Faker::Address.secondary_address,
      correspondence_address3: Faker::Address.city,
      correspondence_postcode: Faker::Address.zip_code,
      property_address: Faker::Address.street_address,
      total_collectable_arrears_balance: Faker::Number.number(3)
    }
  }

  context 'when the letter is being generated' do
    it 'checks that the template file exists' do
      files = Hackney::ServiceCharge::Letter::LetterTwo::TEMPLATE_PATHS

      files.each do |file|
        expect(Pathname.new(file)).to exist
      end
    end
  end

  describe 'fetch letter 1 date' do
    let(:letter) { described_class.new(letter_params) }

    context 'when letter 1 hasn\'t been sent' do
      it 'an error is returned' do
        expect(letter.errors).to eq [
          { message: 'missing mandatory field', name: 'arrears_letter_1_date' }
        ]
      end
    end

    context 'when letter 1 has been sent' do
      before do
        Hackney::Cloud::Document.create(
          metadata: {
            payment_ref: letter_params[:payment_ref],
            template: { name: 'Letter 1' }
          }.to_json,
          uuid: SecureRandom.uuid,
          extension: :foo,
          mime_type: :bar
        )
      end

      it 'no errors are returned' do
        expect(letter.errors).to eq []
      end
    end
  end
end
