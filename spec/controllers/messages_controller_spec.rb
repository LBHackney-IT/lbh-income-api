require 'rails_helper'

describe MessagesController, type: :controller do
  include MessagesHelper

  let(:sms_params) do
    {
      user_id: Faker::Number.number(2),
      tenancy_ref: "#{Faker::Number.number(8)}/#{Faker::Number.number(2)}",
      template_id: Faker::HitchhikersGuideToTheGalaxy.planet,
      phone_number: Faker::PhoneNumber.phone_number,
      reference: Faker::HitchhikersGuideToTheGalaxy.starship,
      variables: {
        'first name' => Faker::HitchhikersGuideToTheGalaxy.character
      }.to_s
    }
  end
  let(:email_params) do
    {
      user_id: Faker::Number.number(2),
      tenancy_ref: "#{Faker::Number.number(8)}/#{Faker::Number.number(2)}",
      template_id: Faker::HitchhikersGuideToTheGalaxy.planet,
      email_address: Faker::Internet.email,
      reference: Faker::HitchhikersGuideToTheGalaxy.starship,
      variables: {
        'first name' => Faker::HitchhikersGuideToTheGalaxy.character
      }.to_s
    }
  end

  let(:dummy_action_diary_usecase) { double(Hackney::Tenancy::AddActionDiaryEntry) }
  let(:expeted_templates) { Hackney::Income::GovNotifyGateway::EXAMPLE_TEMPLATES.to_json }

  before do
    stub_const(
      'Hackney::Income::GovNotifyGateway',
      Hackney::Income::DummyGovNotifyGateway,
      transfer_nested_constants: true
    )

    stub_const('Hackney::Tenancy::AddActionDiaryEntry', dummy_action_diary_usecase)
    allow(dummy_action_diary_usecase).to receive(:new).and_return(dummy_action_diary_usecase)
    allow(dummy_action_diary_usecase).to receive(:execute)
  end

  it 'sends an sms' do
    expect_any_instance_of(Hackney::Income::SendManualSms).to receive(:execute).with(
      user_id: sms_params.fetch(:user_id),
      tenancy_ref: sms_params.fetch(:tenancy_ref),
      template_id: sms_params.fetch(:template_id),
      phone_number: sms_params.fetch(:phone_number),
      reference: sms_params.fetch(:reference),
      variables: sms_params.fetch(:variables)
    ).and_call_original

    patch :send_sms, params: sms_params
    expect(response.status).to eq(204)
  end

  it 'sends an email' do
    expect_any_instance_of(Hackney::Income::SendManualEmail).to receive(:execute).with(
      user_id: email_params.fetch(:user_id),
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
