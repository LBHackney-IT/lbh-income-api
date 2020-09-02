require 'rails_helper'

describe UseCases::GenerateAndStoreLetter do
  include MockAwsHelper

  before do
    mock_aws_client

    stub_response_body = File.read('spec/lib/hackney/pdf/test_bank_holidays_api_response.txt')
    stub_request(:get, 'https://www.gov.uk/bank-holidays.json').to_return(
      status: 200,
      body: stub_response_body
    )

    Rails.cache.delete('Hackney/PDF/BankHolidays')
  end

  let(:use_case) { described_class.new }
  let(:use_case_output) { use_case.execute(params) }
  let(:user_name) { Faker::Name.name }
  let(:email) { Faker::Internet.email }
  let(:user_group) { ['leasehold-group'] }
  let(:payment_ref) { nil }
  let(:tenancy_ref) { nil }
  let(:template_id) { 'letter_1_in_arrears_FH' }

  let(:params) do
    {
      payment_ref: payment_ref,
      tenancy_ref: tenancy_ref,
      template_id: template_id,
      user: Hackney::Domain::User.new.tap do |u|
        u.name = user_name
        u.email = email
        u.groups = [user_group]
      end
    }
  end

  context 'when some data is missing' do
    let(:letter_fields) {
      {
        payment_ref: Faker::Number.number(digits: 4),
        lessee_full_name: Faker::Name.name,
        correspondence_address1: Faker::Address.street_address,
        correspondence_address2: Faker::Address.secondary_address,
        correspondence_address3: Faker::Address.city,
        correspondence_postcode: Faker::Address.zip_code,
        property_address: Faker::Address.street_address,
        total_collectable_arrears_balance: Faker::Number.number(digits: 3)
      }
    }

    context 'when the missing data is optional' do
      let(:payment_ref) { Faker::Number.number(digits: 4) }

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
      let(:payment_ref) { Faker::Number.number(digits: 4) }
      let(:mandatory_fields) { Hackney::Leasehold::Letter::DEFAULT_MANDATORY_LETTER_FIELDS }

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

    context 'when the template is an informal agreement confirmation template' do
      let(:tenancy_ref) { Faker::Number.number(digits: 4).to_s }
      let(:user_group) { ['income-collection-group'] }
      let(:template_id) { 'informal_agreement_confirmation_letter' }

      it 'gets all the data and generates the letter' do
        expect_any_instance_of(Hackney::Income::UniversalHousingIncomeGateway)
          .to receive(:get_income_info).with(tenancy_ref: tenancy_ref)
                                       .and_return(letter_fields)
        expect_any_instance_of(Hackney::Income::SqlTenancyCaseGateway)
          .to receive(:find).with(tenancy_ref: tenancy_ref)
                            .and_return(
                              build(:case_priority,
                                    tenancy_ref: tenancy_ref,
                                    collectable_arrears: Faker::Number.number(digits: 3))
                            )
        expect(Hackney::Income::Models::Agreement)
          .to receive(:where).with(tenancy_ref: tenancy_ref)
                             .and_return([build(:live_agreement, tenancy_ref: tenancy_ref)])

        use_case_output
      end
    end

    context 'when the template is an informal agreement breach letter template' do
      let(:tenancy_ref) { Faker::Number.number(digits: 4).to_s }
      let(:user_group) { ['income-collection-group'] }
      let(:template_id) { 'informal_agreement_breach_letter' }

      it 'gets all the data and generates the letter' do
        expect_any_instance_of(Hackney::Income::UniversalHousingIncomeGateway)
          .to receive(:get_income_info).with(tenancy_ref: tenancy_ref)
                                       .and_return(letter_fields)
        expect_any_instance_of(Hackney::Income::SqlTenancyCaseGateway)
          .to receive(:find).with(tenancy_ref: tenancy_ref)
                            .and_return(
                              build(:case_priority,
                                    tenancy_ref: tenancy_ref,
                                    collectable_arrears: Faker::Number.number(digits: 3))
                            )
        expect(Hackney::Income::Models::Agreement)
          .to receive(:where).with(tenancy_ref: tenancy_ref)
                             .and_return([create(:agreement_state, :breached).agreement])

        use_case_output
      end
    end
  end

  context 'when the template is an formal agreement breach template' do
    let(:letter_fields) {
      {
        payment_ref: Faker::Number.number(digits: 4),
        lessee_full_name: Faker::Name.name,
        correspondence_address1: Faker::Address.street_address,
        correspondence_address2: Faker::Address.secondary_address,
        correspondence_address3: Faker::Address.city,
        correspondence_postcode: Faker::Address.zip_code,
        property_address: Faker::Address.street_address,
        total_collectable_arrears_balance: Faker::Number.number(digits: 3)
      }
    }

    let(:tenancy_ref) { Faker::Number.number(digits: 4).to_s }
    let(:user_group) { ['income-collection-group'] }
    let(:template_id) { 'formal_agreement_breach_letter' }

    let!(:court_case) { create(:court_case, tenancy_ref: tenancy_ref) }
    let!(:agreement) { create(:agreement, tenancy_ref: tenancy_ref, agreement_type: 'formal', court_case_id: court_case.id) }

    before do
      create(:agreement_state, :breached, agreement: agreement)
    end

    it 'gets all the data and generates the letter' do
      expect_any_instance_of(Hackney::Income::UniversalHousingIncomeGateway)
        .to receive(:get_income_info).with(tenancy_ref: tenancy_ref)
                                     .and_return(letter_fields)
      expect_any_instance_of(Hackney::Income::SqlTenancyCaseGateway)
        .to receive(:find).with(tenancy_ref: tenancy_ref)
                          .and_return(
                            build(:case_priority,
                                  tenancy_ref: tenancy_ref,
                                  collectable_arrears: Faker::Number.number(digits: 3))
                          )
      expect(Hackney::Income::Models::Agreement)
        .to receive(:where).with(tenancy_ref: tenancy_ref)
                           .and_return([agreement])

      use_case_output
    end
  end
end
