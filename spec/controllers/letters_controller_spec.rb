require 'rails_helper'

describe LettersController, type: :controller do
  let(:template_path) { 'path/to/temp' }
  let(:template_id) { 'letter_1_in_arrears_FH' }
  let(:template_name) { 'Letter 1 In Arrears FH' }
  let(:preview_html) { "<p>#{Faker::HitchhikersGuideToTheGalaxy.quote}</p>" }

  describe '#get_templates' do
    it 'gets letter templates' do
      expect_any_instance_of(Hackney::PDF::GetTemplates).to receive(:execute).and_return(
        path: template_path,
        id: template_id,
        name: template_name
      )

      get :get_templates

      expect(response.body).to eq(
        {
          path: template_path,
          id: template_id,
          name: template_name
        }.to_json
      )
    end
  end

  describe '#send_letter' do
    context 'when user "accepts" the preview' do
      let(:username) { Faker::Name.name }
      let(:email) { Faker::Internet.email }
      let(:uuid) { SecureRandom.uuid }

      before do
        Rails.cache.write(uuid, preview: preview_html, case: { payment_ref: 123 })
      end

      it 'calls succefully' do
        post :send_letter, params: { uuid: uuid, username: username, email: email }

        expect(response).to be_successful
      end

      it 'calls the usecase' do
        expect_any_instance_of(Hackney::Income::ProcessLetter)
          .to receive(:execute).with(uuid: uuid, username: username, email: email)

        post :send_letter, params: { uuid: uuid, username: username, email: email }
      end
    end
  end

  describe '#create' do
    context 'when all data is is found' do
      let(:found_payment_ref) { Faker::Number.number(4) }
      let(:preview_uuid) { SecureRandom.uuid }

      it 'generates pdf(html) preview with template details, case and empty errors' do
        expect_any_instance_of(Hackney::PDF::PreviewGenerator).to receive(:execute).and_return(html: preview_html, errors: [])
        expect_any_instance_of(Hackney::Income::UniversalHousingLeaseholdGateway)
          .to receive(:get_leasehold_info).with(payment_ref: found_payment_ref).and_return(payment_ref: found_payment_ref)

        post :create, params: { payment_ref: found_payment_ref, template_id: template_id }

        expect(response.status).to eq(200)

        expect(response_json['case']['payment_ref']).to eq(found_payment_ref)
        expect(response_json['template']['id']).to eq(template_id)
        expect(response_json['preview']).to eq(preview_html)
        expect(response_json['uuid']).not_to be_nil
        expect(response_json['errors']).to eq([])
      end
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

          post :create, params: { payment_ref: payment_ref, template_id: template_id }

          expect(response_json['errors']).to eq([])
        end
      end

      context 'when the missing data mandatory' do
        let(:payment_ref) { Faker::Number.number(4) }
        let(:mandatory_fields) { Hackney::ServiceCharge::Letter::MANDATORY_LETTER_FIELDS }

        it 'returns errors' do
          expect_any_instance_of(Hackney::Income::UniversalHousingLeaseholdGateway)
            .to receive(:get_leasehold_info).with(payment_ref: payment_ref).and_return(
              letter_fields.except(*mandatory_fields)
            )

          post :create, params: { payment_ref: payment_ref, template_id: template_id }

          expect(response_json['errors']).to eq(
            [{ 'message' => 'missing mandatory field', 'name' => 'payment_ref' },
             { 'message' => 'missing mandatory field', 'name' => 'lessee_full_name' },
             { 'message' => 'missing mandatory field', 'name' => 'correspondence_address1' },
             { 'message' => 'missing mandatory field', 'name' => 'correspondence_postcode' },
             { 'message' => 'missing mandatory field', 'name' => 'property_address' },
             { 'message' => 'missing mandatory field', 'name' => 'total_collectable_arrears_balance' }]
          )
        end
      end
    end

    context 'when payment_ref is not found' do
      let(:not_found_payment_ref) { 123 }

      it 'returns 404' do
        post :create, params: { payment_ref: not_found_payment_ref, template_id: template_id }

        expect(response.status).to eq(404)
      end
    end
  end

  private

  def response_json
    JSON.parse(response.body)
  end
end
