require 'rails_helper'

describe Hackney::Notification::SendManualSms do
  let(:tenancy) { create_tenancy_model }
  let(:notification_gateway) { Hackney::Income::StubNotificationsGateway.new }
  let(:add_action_diary_and_sync_case_usecase) { double(UseCases::AddActionDiaryAndSyncCase) }
  let(:send_sms) do
    described_class.new(
      notification_gateway: notification_gateway,
      add_action_diary_and_sync_case_usecase: add_action_diary_and_sync_case_usecase
    )
  end

  before do
    tenancy.save
  end

  context 'when sending an SMS manually' do
    subject do
      send_sms.execute(
        username: username,
        tenancy_ref: tenancy.tenancy_ref,
        template_id: template_id,
        phone_number: phone_number,
        reference: reference,
        variables: { 'first name' => first_name }
      )
      notification_gateway.last_text_message
    end

    let(:template_id) { '00004' }
    let(:phone_number) { '07333444555' }
    let(:e164_phone_number) { '+447333444555' }
    let(:reference) { Faker::Superhero.prefix }
    let(:first_name) { Faker::Superhero.name }
    let(:username) { Faker::Name.name }

    before do
      allow(add_action_diary_and_sync_case_usecase).to receive(:execute)
    end

    it 'maps the tenancy to a set of variables' do
      expect(subject).to include(
        variables: include(
          'first name' => first_name
        )
      )
    end

    it 'parses the phone number to full e164 format' do
      expect(subject).to include(
        phone_number: e164_phone_number
      )
    end

    it 'passes through the template id' do
      expect(subject).to include(
        template_id: template_id
      )
    end

    it 'generates a tenant and message representative reference' do
      expect(subject).to include(
        reference: reference
      )
    end

    it 'writes a entry to the action diary using the template friendly name' do
      expect(add_action_diary_and_sync_case_usecase).to receive(:execute)
        .with(
          username: username,
          tenancy_ref: tenancy.tenancy_ref,
          action_code: 'GMS',
          comment: "A Quicker Template' SMS sent to '#{e164_phone_number}' with content 'a body should be here?'"
        )
        .once

      subject
    end

    context 'when sending an invalid number' do
      subject do
        send_sms.execute(
          username: username,
          tenancy_ref: tenancy.tenancy_ref,
          template_id: template_id,
          phone_number: phone_number,
          reference: reference,
          variables: { 'first name' => first_name }
        )
      end

      let(:notification_gateway) { double(Hackney::Notification::GovNotifyGateway) }
      let(:phone_number) { 'not a phone number' }

      it 'does not send an sms' do
        expect(add_action_diary_and_sync_case_usecase).not_to receive(:send_text_message)

        expect do
          subject
        end.to raise_error(
          ArgumentError,
          "Invalid phone number when trying to send manual SMS (reference: '#{reference}') using template_id: #{template_id}"
        )
      end
    end
  end
end
