# frozen_string_literal: true

require 'rails_helper'

describe MessagesController, type: :controller do
  include MessagesHelper

  let(:first_name) { Faker::HitchhikersGuideToTheGalaxy.character }
  let(:sms_params) do
    {
      user_id: Faker::Number.number(2),
      tenancy_ref: "#{Faker::Number.number(8)}/#{Faker::Number.number(2)}",
      template_id: Faker::HitchhikersGuideToTheGalaxy.planet,
      phone_number: Faker::PhoneNumber.phone_number,
      reference: Faker::HitchhikersGuideToTheGalaxy.starship,
      variables: {
        'first name' => first_name
      }
    }
  end

  let(:email_version) { Faker::Number.number(2) }
  let(:email_params) do
    {
      user_id: Faker::Number.number(2),
      tenancy_ref: "#{Faker::Number.number(8)}/#{Faker::Number.number(2)}",
      template_id: Faker::HitchhikersGuideToTheGalaxy.planet,
      email_address: Faker::Internet.email,
      reference: Faker::HitchhikersGuideToTheGalaxy.starship,
      variables: {
        'first name' => first_name
      }
    }
  end

  let(:dummy_action_diary_usecase) { double(Hackney::Tenancy::AddActionDiaryEntry) }
  let(:dummy_sent_messages_usecase) { double(Hackney::Income::SqlSentMessages) }

  before do
    stub_const(
      'Hackney::Income::GovNotifyGateway',
      Hackney::Income::StubGovNotifyGateway,
      transfer_nested_constants: true
    )

    stub_const('Hackney::Tenancy::AddActionDiaryEntry', dummy_action_diary_usecase)
    allow(dummy_action_diary_usecase).to receive(:new).and_return(dummy_action_diary_usecase)
    allow(dummy_action_diary_usecase).to receive(:execute)

    stub_const('Hackney::Income::SqlSentMessages', dummy_sent_messages_usecase)
    allow(dummy_sent_messages_usecase).to receive(:new).and_return(dummy_sent_messages_usecase)
    allow(dummy_sent_messages_usecase).to receive(:add_message)
    allow(dummy_sent_messages_usecase).to receive(:get_sent_messages).and_return([
                                          OpenStruct.new(
                                            id: 1,
                                            tenancy_ref: email_params.fetch(:tenancy_ref),
                                            template_id: email_params.fetch(:template_id),
                                            version: email_version,
                                            message_type: 'email',
                                            personalisation: email_params.fetch(:variables).to_json
                                          )
])
  end

  let(:expeted_templates) do
    Hackney::Income::GovNotifyGateway::EXAMPLE_TEMPLATES.to_json
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
    ).and_return(OpenStruct.new(template: { 'version': 3 }))

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

  it 'gets sent emails' do
    expect_any_instance_of(Hackney::Income::GetSentMessages).to receive(:execute).with(
      type: 'email',
      tenancy_ref: email_params.fetch(:tenancy_ref)
    ).and_call_original

    get :get_sent_messages, params: { type: 'email', tenancy_ref: email_params.fetch(:tenancy_ref) }

    expect(response.body).to eq([{ "table": {
                                  "id": email_params.fetch(:template_id),
                                  "version": email_version,
                                  "body": "Hi #{first_name}",
                                  "subject": 'subject',
                                  "type": 'email'
                                } }].to_json)
  end
end
