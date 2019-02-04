require 'rails_helper'

describe Hackney::Income::SendAutomatedEmail do
  let(:notification_gateway) { Hackney::Income::StubNotificationsGateway.new }
  let(:background_job_gateway) { double(Hackney::Income::BackgroundJobGateway) }
  let(:send_email) { described_class.new(notification_gateway: notification_gateway, background_job_gateway: background_job_gateway) }
  let(:tenancy_1) { create_tenancy_model }

  context 'when sending an email automatically' do
    subject do
      send_email.execute(
        tenancy_ref: tenancy_1.tenancy_ref,
        recipient: recipient,
        template_id: template_id,
        reference: reference,
        variables: { 'first name' => first_name }
      )
      notification_gateway.last_email
    end

    let(:recipient) { Faker::Internet.email }
    let(:template_id) { '00001' }
    let(:reference) { Faker::Superhero.prefix }
    let(:first_name) { Faker::Superhero.name }

    it 'maps the tenancy to a set of variables' do
      expect(background_job_gateway).to receive(:add_action_diary_entry)
      expect(subject).to include(
        variables: include(
          'first name' => first_name
        )
      )
    end

    it 'passes through email address from the primary contact' do
      expect(background_job_gateway).to receive(:add_action_diary_entry)
      expect(subject).to include(
        recipient: recipient
      )
    end

    it 'passes through the template id' do
      expect(background_job_gateway).to receive(:add_action_diary_entry)
      expect(subject).to include(
        template_id: template_id
      )
    end

    it 'generates a tenant and message representative reference' do
      expect(background_job_gateway).to receive(:add_action_diary_entry)
      expect(subject).to include(
        reference: reference
      )
    end

    it 'makes an action diary entry' do
      expect(background_job_gateway).to receive(:add_action_diary_entry).with(
        tenancy_ref: tenancy_1.tenancy_ref,
        action_code: Hackney::Tenancy::ActionCodes::AUTOMATED_SMS_ACTION_CODE,
        comment: "'Quick Template' email sent to '#{recipient}'"
      )
      subject
    end
  end
end
