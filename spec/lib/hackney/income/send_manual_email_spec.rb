require 'rails_helper'

describe Hackney::Income::SendManualEmail do
  let(:notification_gateway) { Hackney::Income::StubNotificationsGateway.new }
  let(:add_action_diary_usecase) { instance_double(Hackney::Tenancy::AddActionDiaryEntry) }
  let(:send_email) { described_class.new(notification_gateway: notification_gateway, add_action_diary_usecase: add_action_diary_usecase) }
  let(:tenancy_1) { create_tenancy_model }

  context 'when sending an email manually' do
    subject do
      send_email.execute(
        user_id: user_id,
        tenancy_ref: tenancy_1.tenancy_ref,
        recipient: recipient,
        template_id: template_id,
        reference: reference,
        variables: { 'first name' => first_name }
      )
      notification_gateway.last_email
    end

    let(:template_id) { '00001' }
    let(:recipient) { Faker::Internet.safe_email }
    let(:reference) { Faker::Superhero.prefix }
    let(:first_name) { Faker::Superhero.name }
    let(:user_id) { Faker::Number.number(2) }

    before do
      allow(add_action_diary_usecase).to receive(:execute)
    end

    it 'maps the tenancy to a set of variables' do
      expect(subject).to include(
        variables: include(
          'first name' => first_name
        )
      )
    end

    it 'passes through email address from the primary contact' do
      expect(subject).to include(
        recipient: recipient
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

    it 'calls action_diary_usecase' do
      expect(add_action_diary_usecase).to receive(:execute)
        .with(
          user_id: user_id,
          tenancy_ref: tenancy_1.tenancy_ref,
          action_code: 'GME',
          comment: "'Quick Template' Email sent to '#{recipient}'"
        )
        .once

      subject
    end
  end
end
