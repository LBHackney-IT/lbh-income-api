require 'rails_helper'

describe LettersController, type: :controller do
  let(:template_path) { 'path/to/temp' }
  let(:template_id) { 'letter_1_in_arrears_FH' }
  let(:template_name) { 'Letter 1 In Arrears FH' }
  let(:user_group) { Hackney::PDF::GetTemplates::LEASEHOLD_SERVICES_GROUP }
  let(:user) {
    {
      id: 1,
      name: Faker::Name.name,
      email: Faker::Internet.email,
      groups: [user_group]
    }.to_json
  }

  describe '#get_templates' do
    it 'gets letter templates' do
      expect_any_instance_of(Hackney::PDF::GetTemplates)
        .to receive(:execute)
        .with(user_groups: [user_group]).and_return(
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

  describe '#create' do
    let(:generate_and_store_use_case_spy) { spy }
    let(:payment_ref) { Faker::Number.number(6) }
    let(:username) { Faker::Name.name }
    let(:email) { Faker::Internet.email }
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
