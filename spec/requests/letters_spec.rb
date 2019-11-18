require 'rails_helper'

RSpec.describe 'Letters', type: :request do
  include MockAwsHelper

  let(:property_ref) { Faker::Number.number(4) }
  let(:tenancy_ref) { "#{Faker::Number.number(6)}/#{Faker::Number.number(2)}" }
  let(:payment_ref) { Faker::Number.number(4) }
  let(:house_ref) { Faker::Number.number(4) }
  let(:postcode) { Faker::Address.postcode }
  let(:leasedate) { Time.zone.now.beginning_of_hour }
  let(:template) { 'letter_1_in_arrears_FH' }
  let(:user_group) { Hackney::PDF::GetTemplates::LEASEHOLD_SERVICES_GROUP }
  let(:username) { Faker::Name.name }
  let(:email) { Faker::Internet.email }

  let(:user) {
    Hackney::Domain::User.new.tap do |u|
      u.name = username
      u.email = email
      u.groups = [user_group]
    end
  }

  before do
    mock_aws_client
    create_valid_uh_records_for_a_letter
  end

  describe 'POST /api/v1/messages/letters' do
    it 'returns 404 with bogus payment ref' do
      post messages_letters_path, params: {
        payment_ref: 'abc',
        template_id: 'letter_1_in_arrears_FH',
        user: user.to_json
      }

      expect(response).to have_http_status(404)
    end

    it 'raises an error with bogus template_id' do
      expect {
        post messages_letters_path, params: {
          payment_ref: 'abc',
          template_id: 'does not exist',
          user: user.to_json
        }
      }.to raise_error(TypeError)
    end

    context 'with valid payment ref' do
      let(:expected_json_response_as_hash) {
        {
          'case' => {
            'bal_dispute' => '0.0',
            'charging_order' => '0.0',
            'money_judgement' => '0.0',
            'tenure_type' => 'SEC',
            'payment_ref' => payment_ref,
            'tenancy_ref' => tenancy_ref,
            'total_collectable_arrears_balance' => '0.0',
            'original_lease_date' => leasedate.strftime('%FT%T.%L%:z'),
            'lessee_full_name' => 'Test Name',
            'lessee_short_name' => 'Test Name', 'date_of_current_purchase_assignment' => '1900-01-01T00:00:00.000+00:00',
            'correspondence_address1' => 'Test',
            'correspondence_address2' => 'Test Test Line 1', 'correspondence_address3' => '',
            'correspondence_address4' => '',
            'correspondence_address5' => '',
            'correspondence_postcode' => postcode,
            'property_address' => ", #{postcode}",
            'international' => false
          },
          'template' => {
            'path' => 'lib/hackney/pdf/templates/leasehold/letter_1_in_arrears_FH.erb',
            'name' => 'Letter 1 in arrears fh',
            'id' => 'letter_1_in_arrears_FH'
          },
          'username' => username,
          'document_id' => 1,
          'errors' => []
        }
      }

      it 'responds with a JSON object' do
        post messages_letters_path, params: {
          payment_ref: payment_ref,
          template_id: template,
          user: user.to_json
        }

        # UUID: is always different can ignore this.
        # TODO: Test `preview` content separatly
        keys_to_ignore = %w[preview uuid]

        json_response = JSON.parse(response.body).except(*keys_to_ignore)

        expect(json_response).to eq(expected_json_response_as_hash)
      end

      it 'creates a `Hackney::Cloud::Document`' do
        expect {
          post messages_letters_path, params: {
            payment_ref: payment_ref,
            template_id: template,
            user: user.to_json
          }
        }.to change { Hackney::Cloud::Document.count }.from(0).to(1)
      end

      it 'stores the User ID on metadata of the Document' do
        post messages_letters_path, params: {
          payment_ref: payment_ref,
          template_id: template,
          user: user.to_json
        }

        document = Hackney::Cloud::Document.last
        expect(JSON.parse(document.metadata)['username']).to eq(username)
        expect(JSON.parse(document.metadata)['template']['id']).to eq(template)
        expect(JSON.parse(document.metadata)['payment_ref']).to eq(payment_ref)
      end
    end
  end

  describe 'POST /api/v1/messages/letters/send' do
    let(:uuid) { existing_letter[:uuid] }
    let(:username) { Faker::Name.name }
    let(:email) { Faker::Internet.email }
    let(:existing_letter) do
      generate_and_store_letter(
        payment_ref: payment_ref,
        template_id: template,
        user: user
      )
    end

    context 'when there is an existing letter' do
      before do
        existing_letter
      end

      it 'is a No Content (204) status' do
        post messages_letters_send_path, params: {
          uuid: uuid,
          user: user
        }
        expect(response).to be_no_content
      end

      it 'adds a `Hackney::Income::Jobs::SendLetterToGovNotifyJob` to ActiveJob' do
        expect {
          post messages_letters_send_path, params: {
            uuid: uuid,
            user: user
          }
        }.to have_enqueued_job(Hackney::Income::Jobs::SendLetterToGovNotifyJob)
      end

      it "stores the User's details on metadata of the Document" do
        post messages_letters_send_path, params: {
          uuid: uuid,
          user: user
        }

        document = Hackney::Cloud::Document.last
        expect(JSON.parse(document.metadata)['username']).to eq(username)
      end

      context 'with a bogus UUID' do
        it 'throws a `ActiveRecord::RecordNotFound`' do
          expect {
            post messages_letters_send_path, params: {
              uuid: SecureRandom.uuid, username: username, email: email, user_groups: user_group
            }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'when there is no existing letter' do
      context 'with a random UUID' do
        it 'throws a `ActiveRecord::RecordNotFound`' do
          expect {
            post messages_letters_send_path, params: { uuid: SecureRandom.uuid, username: username, email: email }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  def create_valid_uh_records_for_a_letter
    create_uh_property(
      property_ref: property_ref,
      post_code: postcode
    )
    create_uh_tenancy_agreement(
      tenancy_ref: tenancy_ref,
      u_saff_rentacc: payment_ref,
      prop_ref: property_ref,
      house_ref: house_ref
    )
    create_uh_househ(
      house_ref: house_ref,
      prop_ref: property_ref,
      corr_preamble: 'Test',
      corr_desig: 'Test',
      corr_postcode: postcode,
      house_desc: 'Test Name'
    )
    create_uh_postcode(
      post_code: postcode,
      aline1: 'Test Line 1'
    )
    create_uh_rent(prop_ref: property_ref, sc_leasedate: leasedate)
  end

  def generate_and_store_letter(payment_ref:, template_id:, user:)
    UseCases::GenerateAndStoreLetter.new.execute(
      payment_ref: payment_ref,
      template_id: template_id,
      user: user
    )
  end
end
