require 'rails_helper'

describe MessagesController, type: :controller do
  include MessagesHelper

  let(:phone_number) { '07333444555' }
  let(:reference) { Faker::Movies::HitchhikersGuideToTheGalaxy.starship }
  let(:template_id) { Hackney::Notification::GovNotifyGateway::EXAMPLE_TEMPLATES.sample[:id] }
  let(:sms_params) do
    {
      username: Faker::Name.name,
      tenancy_ref: "#{Faker::Number.number(8)}/#{Faker::Number.number(2)}",
      template_id: template_id,
      phone_number: phone_number,
      reference: reference,
      variables: {
        'first name' => Faker::Movies::HitchhikersGuideToTheGalaxy.character
      }.to_s
    }
  end
  let(:email_params) do
    {
      username: Faker::Name.name,
      tenancy_ref: "#{Faker::Number.number(digits: 8)}/#{Faker::Number.number(digits: 2)}",
      template_id: Faker::Movies::HitchhikersGuideToTheGalaxy.planet,
      email_address: Faker::Internet.email,
      reference: Faker::Movies::HitchhikersGuideToTheGalaxy.starship,
      variables: {
        'first name' => Faker::Movies::HitchhikersGuideToTheGalaxy.character
      }.to_s
    }
  end

  let(:dummy_action_diary_usecase) { double(UseCases::AddActionDiaryAndSyncCase) }
  let(:expeted_templates) { Hackney::Notification::GovNotifyGateway::EXAMPLE_TEMPLATES.to_json }

  before do
    stub_const(
      'Hackney::Notification::GovNotifyGateway',
      Hackney::Notification::DummyGovNotifyGateway,
      transfer_nested_constants: true
    )

    stub_const('UseCases::AddActionDiaryAndSyncCase', dummy_action_diary_usecase)
    allow(dummy_action_diary_usecase).to receive(:new).and_return(dummy_action_diary_usecase)
    allow(dummy_action_diary_usecase).to receive(:execute)
  end

  it 'sends an sms' do
    expect_any_instance_of(Hackney::Notification::SendManualSms).to receive(:execute).with(
      username: sms_params.fetch(:username),
      tenancy_ref: sms_params.fetch(:tenancy_ref),
      template_id: sms_params.fetch(:template_id),
      phone_number: sms_params.fetch(:phone_number),
      reference: sms_params.fetch(:reference),
      variables: sms_params.fetch(:variables)
    ).and_call_original

    patch :send_sms, params: sms_params
    expect(response.status).to eq(204)
  end

  context 'when fails to send sms' do
    let(:phone_number) { '02035618998' }

    it 'returns an error message' do
      expect_any_instance_of(Hackney::Notification::SendManualSms).to receive(:execute).with(
        username: sms_params.fetch(:username),
        tenancy_ref: sms_params.fetch(:tenancy_ref),
        template_id: sms_params.fetch(:template_id),
        phone_number: sms_params.fetch(:phone_number),
        reference: sms_params.fetch(:reference),
        variables: sms_params.fetch(:variables)
      ).and_call_original

      patch :send_sms, params: sms_params
      expect(response.status).to eq(422)

      json = JSON.parse(response.body, symbolize_names: true)

      expect(json).to eq(
        code: 422,
        message: "Invalid phone number when trying to send manual SMS (reference: '#{reference}') using template_id: #{template_id}",
        status: 'error'
      )
    end
  end

  it 'sends an email' do
    expect_any_instance_of(Hackney::Notification::SendManualEmail).to receive(:execute).with(
      username: email_params.fetch(:username),
      tenancy_ref: email_params.fetch(:tenancy_ref),
      template_id: email_params.fetch(:template_id),
      recipient: email_params.fetch(:email_address),
      reference: email_params.fetch(:reference),
      variables: email_params.fetch(:variables)
    ).and_call_original

    patch :send_email, params: email_params

    expect(response.status).to eq(204)
  end

  it 'gets email templates' do
    expect_any_instance_of(Hackney::Income::GetTemplates).to receive(:execute).with(
      type: 'email'
    ).and_call_original

    patch :get_templates, params: { type: 'email' }

    expect(response.body).to eq(expeted_templates)
  end

  it 'gets sms templates' do
    expect_any_instance_of(Hackney::Income::GetTemplates).to receive(:execute).with(
      type: 'sms'
    ).and_call_original

    patch :get_templates, params: { type: 'sms' }

    expect(response.body).to eq(expeted_templates)
  end
end
