require 'rails_helper'

describe LettersController, type: :controller do
  let(:template_path) { 'path/to/temp' }
  let(:template_id) { 'letter_1_in_arrears_FH' }
  let(:template_name) { 'Letter 1 In Arrears FH' }
  let(:uuid) { '12345' }

  let(:user) {
    {
      name: Faker::Name.name,
      email: Faker::Internet.email,
      groups: %w[leasehold-group income-group]
    }
  }

  describe '#get_templates' do
    it 'gets letter templates' do
      expect_any_instance_of(Hackney::PDF::GetTemplatesForUser)
        .to receive(:execute)
        .with(user: having_attributes(user)).and_return(
          path: template_path,
          id: template_id,
          name: template_name
        )

      get :get_templates, params: { user: user }

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
    let(:send_letter_to_gov_notify) { double }
    let(:find_document) { double }

    let(:tenancy_ref) { Faker::Number.number(4) }
    let(:document) { Hackney::Cloud::Document.new }

    before do
      allow(controller).to receive(:find_document).and_return(document)
      allow(controller).to receive(:send_letter_to_gov_notify).and_return(send_letter_to_gov_notify)
      allow(send_letter_to_gov_notify).to receive(:perform_later)
    end

    it 'calls the send_letter_to_gov_notify job' do
      post :send_letter, params: {
        uuid: uuid,
        user: user,
        tenancy_ref: tenancy_ref
      }

      expect(send_letter_to_gov_notify).to have_received(:perform_later).with(
        document_id: document.id,
        tenancy_ref: tenancy_ref
      )
    end
  end

  describe '#create' do
    let(:generate_and_store_use_case_spy) { spy }
    let(:payment_ref) { Faker::Number.number(6) }
    let(:dummy_json_hash) { { uuid: SecureRandom.uuid } }

    before do
      allow(controller).to receive(:generate_and_store_use_case).and_return(
        generate_and_store_use_case_spy
      )
    end

    context 'when all data is is found' do
      it 'generates pdf(html) preview with template details, case and empty errors' do
        expect(generate_and_store_use_case_spy).to receive(:execute).and_return(dummy_json_hash)

        post :create, params: {
          payment_ref: payment_ref,
          template_id: template_id,
          user: user
        }

        expect(response.status).to eq(200)
      end
    end

    context 'when payment_ref is not found' do
      let(:not_found_payment_ref) { 123 }

      it 'returns 404' do
        expect(generate_and_store_use_case_spy).to receive(:execute).and_raise(Hackney::Income::TenancyNotFoundError)

        post :create, params: {
          payment_ref: not_found_payment_ref,
          template_id: template_id,
          user: user
        }

        expect(response.status).to eq(404)
      end
    end
  end
end
