require 'rails_helper'

describe Hackney::Income::SendAutomatedSms do
  let(:tenancy) { create_tenancy_model }
  let(:notification_gateway) { double(Hackney::Income::GovNotifyGateway) }
  let(:background_job_gateway) { double(Hackney::Income::BackgroundJobGateway) }
  let(:gov_notify_template_name) { Faker::Superhero.name }
  let(:send_sms) do
    described_class.new(
      notification_gateway: notification_gateway,
      background_job_gateway: background_job_gateway
    )
  end

  before do
    tenancy.save
  end

  context 'when sending an SMS automatically' do
    subject do
      send_sms.execute(
        tenancy_ref: tenancy.tenancy_ref,
        template_id: template_id,
        phone_number: phone_number,
        reference: reference,
        variables: { 'first name': first_name }
      )
    end

    let(:template_id) { Faker::Superhero.power }
    let(:phone_number) { '020 8356 3000' }
    let(:e164_phone_number) { '+442083563000' }
    let(:reference) { Faker::Superhero.prefix }
    let(:first_name) { Faker::Superhero.name }

    context 'when when number is valid' do
      before do
        expect(notification_gateway).to receive(:get_template_name).with(template_id).and_return(gov_notify_template_name).once
      end

      it 'passes vars to the gateway' do
        allow(background_job_gateway).to receive(:add_action_diary_entry)
        expect(notification_gateway).to receive(:send_text_message)
          .with(
            variables: {
              'first name': first_name
            },
            phone_number: e164_phone_number,
            template_id: template_id,
            reference: reference
          ).once
        subject
      end

      it 'validates and format a full e164 phone number, assuming local numbers are from uk' do
        allow(background_job_gateway).to receive(:add_action_diary_entry)

        expect(notification_gateway)
          .to receive(:send_text_message)
          .with(include(phone_number: e164_phone_number))
          .once

        subject
      end

      it 'queues a job to write to the action diary' do
        allow(notification_gateway).to receive(:send_text_message)
        expect(background_job_gateway).to receive(:add_action_diary_entry)
          .with(
            tenancy_ref: tenancy.tenancy_ref,
            action_code: Hackney::Tenancy::ActionCodes::AUTOMATED_SMS_ACTION_CODE,
            comment: "'#{gov_notify_template_name}' SMS sent to '#{e164_phone_number}'"
          )
        subject
      end
    end

    context 'when number is invalid' do
      let(:phone_number) { 'there should be no number in this string' }

      it 'does not call gateway and return false' do
        expect(notification_gateway).not_to receive(:get_template_name)
        expect(notification_gateway).not_to receive(:send_text_message)
        subject
      end
    end
  end
end
