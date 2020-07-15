require 'rails_helper'

RSpec.describe 'Income Collection Letters', type: :request do
  include MockAwsHelper

  let(:property_ref) { Faker::Number.number(digits: 4).to_s }
  let(:tenancy_ref) { "#{Faker::Number.number(digits: 6)}/#{Faker::Number.number(digits: 2)}" }
  let(:payment_ref) { Faker::Number.number(digits: 4).to_s }
  let(:house_ref) { Faker::Number.number(digits: 4).to_s }
  let(:postcode) { Faker::Address.postcode }
  let(:leasedate) { Time.zone.now.beginning_of_hour }
  let(:template) { 'income_collection_letter_1' }
  let(:user_group) { 'income-collection-group' }
  let(:current_balance) { BigDecimal('525.00') }
  let(:collectable_arrears) { 486.90 }

  let(:name) { Faker::Name.name }

  let(:user) {
    {
      name: name,
      email: Faker::Internet.email(name: name),
      groups: [user_group]
    }
  }

  before do
    mock_aws_client
    create_valid_uh_records_for_an_income_letter
    Hackney::Income::Models::CasePriority.create!(
      tenancy_ref: tenancy_ref,
      collectable_arrears: collectable_arrears
    )
  end

  describe 'POST /api/v1/messages/letters' do
    it 'returns 404 with bogus tenancy ref' do
      post messages_letters_path, params: {
        tenancy_ref: 'abc', template_id: 'income_collection_letter_1', user: user
      }

      expect(response).to have_http_status(:not_found)
    end

    it 'raises an error with bogus template_id' do
      expect {
        post messages_letters_path, params: {
          tenancy_ref: 'abc', template_id: 'does not exist', user: user
        }
      }.to raise_error(TypeError)
    end

    context 'with valid tenancy ref' do
      let(:expected_json_response_as_hash) {
        {
          'case' => {
            'tenancy_ref' => tenancy_ref,
            'payment_ref' => payment_ref,
            'address_line1' => '12 Acacia House',
            'address_line2' => 'Lordship Road',
            'address_line3' => 'London',
            'address_line4' => '',
            'address_post_code' => postcode,
            'property_ref' => property_ref,
            'forename' => 'Frank',
            'surname' => 'Enstein',
            'title' => 'Mr',
            'total_collectable_arrears_balance' => collectable_arrears.to_s
          },
          'template' => {
            'path' => 'lib/hackney/pdf/templates/income/income_collection_letter_1.erb',
            'name' => 'Income collection letter 1',
            'id' => 'income_collection_letter_1'
          },
          'username' => user[:name],
          'errors' => []
        }
      }

      it 'responds with a JSON object' do
        post messages_letters_path, params: {
          tenancy_ref: tenancy_ref, template_id: template, user: user
        }

        expect(response).to be_successful

        # UUID: is always different can ignore this.
        # TODO: Test `preview` content separatly
        keys_to_ignore = %w[preview uuid document_id]

        full_response = JSON.parse(response.body)
        filtered_response = full_response.except(*keys_to_ignore)

        expect(filtered_response).to eq(expected_json_response_as_hash)

        keys_to_ignore.each do |key|
          expect(full_response).to have_key(key)
        end
      end
    end
  end

  describe 'POST /api/v1/messages/letters/send' do
    let(:existing_income_collection_letter) do
      generate_and_store_letter(
        tenancy_ref: tenancy_ref, template_id: template, user: user
      )
    end

    context 'when there is an existing income collection letter' do
      let(:uuid) { existing_income_collection_letter[:uuid] }

      before do
        existing_income_collection_letter
      end

      it 'is a No Content (204) status' do
        post messages_letters_send_path, params: { uuid: uuid, user: user }

        expect(response).to be_no_content
      end
    end
  end

  def create_valid_uh_records_for_an_income_letter
    create_uh_property(
      property_ref: property_ref,
      post_code: postcode,
      post_preamble: '12 Acacia House',
      post_desig: ''
    )
    create_uh_tenancy_agreement(
      tenancy_ref: tenancy_ref,
      u_saff_rentacc: payment_ref,
      prop_ref: property_ref,
      house_ref: house_ref,
      current_balance: current_balance
    )
    create_uh_househ(
      house_ref: house_ref,
      prop_ref: property_ref,
      corr_preamble: 'Flat 13 Test House',
      corr_desig: '29',
      corr_postcode: postcode,
      house_desc: ''
    )
    create_uh_postcode(
      post_code: postcode,
      aline1: 'Lordship Road',
      aline2: 'London'
    )
    create_uh_member(
      house_ref: house_ref,
      title: 'Mr',
      forename: 'Frank',
      surname: 'Enstein'
    )
    create_uh_rent(prop_ref: property_ref, sc_leasedate: leasedate)
  end

  def generate_and_store_letter(tenancy_ref:, template_id:, user:)
    user_obj = Hackney::Domain::User.new.tap do |u|
      u.name = user[:name]
      u.email = user[:email]
      u.groups = user[:groups]
    end

    UseCases::GenerateAndStoreLetter.new.execute(
      tenancy_ref: tenancy_ref,
      payment_ref: nil,
      template_id: template_id,
      user: user_obj
    )
  end
end
