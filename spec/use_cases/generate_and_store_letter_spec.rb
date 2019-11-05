require 'rails_helper'

describe UseCases::GenerateAndStoreLetter do
  include MockAwsHelper

  before do
    mock_aws_client
  end

  let(:use_case) { described_class.new }
  let(:use_case_output) { use_case.execute(params) }
  let(:user) { create(:user) }
  let(:params) do
    {
      payment_ref: payment_ref,
      template_id: 'letter_1_in_arrears_FH',
      user_id: user.id
    }
  end

  context 'when some data is missing' do
    let(:letter_fields) {
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

    context 'when the missing data is optional' do
      let(:payment_ref) { Faker::Number.number(4) }

      let(:optional_fields) { %i[correspondence_address3] }

      it 'returns no errors' do
        expect_any_instance_of(Hackney::Income::UniversalHousingLeaseholdGateway)
          .to receive(:get_leasehold_info).with(payment_ref: payment_ref)
                                          .and_return(letter_fields.except(*optional_fields))

        json = use_case_output

        expect(json[:errors]).to eq([])
      end
    end

    context 'when the missing data mandatory' do
      let(:payment_ref) { Faker::Number.number(4) }
      let(:mandatory_fields) { Hackney::ServiceCharge::Letter::DEFAULT_MANDATORY_LETTER_FIELDS }

      it 'returns errors' do
        expect_any_instance_of(Hackney::Income::UniversalHousingLeaseholdGateway)
          .to receive(:get_leasehold_info).with(payment_ref: payment_ref).and_return(
            letter_fields.except(*mandatory_fields)
          )

        json = use_case_output

        expect(json[:errors]).to eq(
          [
            { message: 'missing mandatory field', name: 'payment_ref' },
            { message: 'missing mandatory field', name: 'lessee_full_name' },
            { message: 'missing mandatory field', name: 'correspondence_address1' },
            { message: 'missing mandatory field', name: 'correspondence_postcode' },
            { message: 'missing mandatory field', name: 'property_address' },
            { message: 'missing mandatory field', name: 'total_collectable_arrears_balance' }
          ]
        )
      end
    end
  end
end
