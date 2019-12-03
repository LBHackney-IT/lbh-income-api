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
  let(:user_group) { 'leasehold-group' }
  let(:total_collectable_arrears_balance) { Faker::Number.number(3).to_f }
  let(:money_judgement) { Faker::Number.number(2).to_f }
  let(:lba_balance) { BigDecimal(total_collectable_arrears_balance.to_s) - BigDecimal(money_judgement.to_s) }

  let(:user) {
    {
      name: Faker::Name.name,
      email: Faker::Internet.email,
      groups: [user_group]
    }
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
        tenancy_ref: tenancy_ref,
        user: user
      }

      expect(response).to have_http_status(404)
    end

    it 'raises an error with bogus template_id' do
      expect {
        post messages_letters_path, params: {
          payment_ref: 'abc',
          template_id: 'does not exist',
          tenancy_ref: 'abd',
          user: user
        }
      }.to raise_error(TypeError)
    end

    context 'with valid payment ref' do
      let(:expected_json_response_as_hash) {
        {
          'case' => {
            'bal_dispute' => '0.0',
            'charging_order' => '0.0',
            'money_judgement' => money_judgement.to_s,
            'tenure_type' => 'SEC',
            'payment_ref' => payment_ref,
            'tenancy_ref' => tenancy_ref,
            'total_collectable_arrears_balance' => total_collectable_arrears_balance.to_s,
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
          'username' => user[:name],
          'document_id' => Hackney::Cloud::Document.last.id,
          'errors' => []
        }
      }

      it 'responds with a JSON object' do
        post messages_letters_path, params: {
          payment_ref: payment_ref,
          template_id: template,
          tenancy_ref: tenancy_ref,
          user: user
        }

        # UUID: is always different can ignore this.
        # TODO: Test `preview` content separatly
        keys_to_ignore = %w[preview uuid]

        json_response = JSON.parse(response.body).except(*keys_to_ignore)

        expect(json_response).to eq(expected_json_response_as_hash)
      end

      it 'generates an LBA with an lba_balance' do
        post messages_letters_path, params: {
          payment_ref: payment_ref,
          template_id: 'letter_before_action',
          tenancy_ref: tenancy_ref,
          user: user
        }

        json_response = JSON.parse(response.body)

        expect(json_response['preview']).to include("SUM OWED: £#{lba_balance}")
      end

      it 'creates a `Hackney::Cloud::Document`' do
        expect {
          post messages_letters_path, params: {
            payment_ref: payment_ref,
            template_id: template,
            tenancy_ref: tenancy_ref,
            user: user
          }
        }.to change { Hackney::Cloud::Document.count }.from(0).to(1)
      end

      it 'stores the User ID on metadata of the Document' do
        post messages_letters_path, params: {
          payment_ref: payment_ref,
          template_id: template,
          tenancy_ref: tenancy_ref,
          user: user
        }

        document = Hackney::Cloud::Document.last
        expect(JSON.parse(document.metadata)['username']).to eq(user[:name])
        expect(JSON.parse(document.metadata)['template']['id']).to eq(template)
        expect(JSON.parse(document.metadata)['payment_ref']).to eq(payment_ref)
      end
    end
  end

  describe 'POST /api/v1/messages/letters/send' do
    let(:uuid) { existing_letter[:uuid] }
    let(:username) { Faker::Name.name }
    let(:email) { Faker::Internet.email }
    let(:existing_leasehold_letter) do
      generate_and_store_letter(
        payment_ref: payment_ref, tenancy_ref: tenancy_ref, template_id: template, user: user
      )
    end
    let(:existing_income_collection_letter) do
      document = create(:document)
      metadata = JSON.parse(document.metadata)
      metadata['template']['id'] = 'income_collection_letter_1'
      document.update(metadata: metadata.to_json)
      document
    end

    context 'when there is an existing leasehold letter' do
      let(:uuid) { existing_leasehold_letter[:uuid] }

      before do
        existing_leasehold_letter
      end

      it 'is a No Content (204) status' do
        post messages_letters_send_path, params: {
          uuid: uuid
        }
        expect(response).to be_no_content
      end

      it 'adds a `Hackney::Income::Jobs::SendLetterToGovNotifyJob` to ActiveJob' do
        expect {
          post messages_letters_send_path, params: {
            uuid: uuid
          }
        }.to have_enqueued_job(Hackney::Income::Jobs::SendLetterToGovNotifyJob)
      end

      it "stores the User's details on metadata of the Document" do
        post messages_letters_send_path, params: {
          uuid: uuid
        }

        document = Hackney::Cloud::Document.last
        expect(JSON.parse(document.metadata)['username']).to eq(user[:name])
      end

      context 'with a bogus UUID' do
        it 'throws a `ActiveRecord::RecordNotFound`' do
          expect {
            post messages_letters_send_path, params: {
              uuid: SecureRandom.uuid
            }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'when there is no existing letter' do
      context 'with a random UUID' do
        it 'throws a `ActiveRecord::RecordNotFound`' do
          expect {
            post messages_letters_send_path, params: { uuid: SecureRandom.uuid, user: user }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'when there is an existing income collection letter' do
      let(:uuid) { existing_income_collection_letter[:uuid] }

      before do
        existing_income_collection_letter
      end

      it 'is a No Content (204) status' do
        post messages_letters_send_path, params: { uuid: uuid, username: username, email: email }

        expect(response).to be_no_content
      end

      it 'adds a `Hackney::Income::Jobs::SendIncomeCollectionLetterToGovNotifyJob` to ActiveJob' do
        expect {
          post messages_letters_send_path, params: { uuid: uuid, username: username, email: email }
        }.to have_enqueued_job(Hackney::Income::Jobs::SendLetterToGovNotifyJob)
      end

      context 'with a bogus UUID' do
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
      house_ref: house_ref,
      current_balance: total_collectable_arrears_balance,
      money_judgement: money_judgement
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

  def generate_and_store_letter(payment_ref:, tenancy_ref:, template_id:, user:)
    user_obj = Hackney::Domain::User.new.tap do |u|
      u.name = user[:name]
      u.email = user[:email]
      u.groups = user[:groups]
    end

    UseCases::GenerateAndStoreLetter.new.execute(
      payment_ref: payment_ref,
      tenancy_ref: tenancy_ref,
      template_id: template_id,
      user: user_obj
    )
  end
end
