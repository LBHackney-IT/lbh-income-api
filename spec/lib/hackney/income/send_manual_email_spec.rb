require 'rails_helper'

describe Hackney::Income::SendManualEmail do
  let(:notification_gateway) { Hackney::Income::StubNotificationsGateway.new }
  let(:add_action_diary_usecase) { double(Hackney::Tenancy::AddActionDiaryEntry) }
  let(:sql_sent_messages_usecase) { double(Hackney::Income::SqlSentMessages) }

  let(:send_email) {
    described_class.new(
      notification_gateway: notification_gateway,
      add_action_diary_usecase: add_action_diary_usecase,
      sql_sent_messages_usecase: sql_sent_messages_usecase
    )
  }

  let(:tenancy_1) { create_tenancy_model }

  context 'when sending an email manually' do
    let(:template_id) { Faker::Superhero.power }
    let(:recipient) { Faker::Internet.email }
    let(:reference) { Faker::Superhero.prefix }
    let(:first_name) { Faker::Superhero.name }
    let(:user_id) { Faker::Number.number(2) }

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

    before do
      allow(add_action_diary_usecase).to receive(:execute)
      allow(sql_sent_messages_usecase).to receive(:add_message)
    end

    it 'should map the tenancy to a set of variables' do
      expect(subject.variables).to eq('first name' => first_name)
    end

    it 'should pass through email address from the primary contact' do
      expect(subject.recipient).to eq(recipient)
    end

    it 'should pass through the template id' do
      expect(subject.template).to include(
        template_id: template_id
      )
    end

    it 'should generate a tenant and message representative reference' do
      expect(subject.reference).to eq(reference)
    end

    it 'should call sql_sent_messages_usecase' do
      expect(sql_sent_messages_usecase).to receive(:add_message)
        .with(
          tenancy_ref: tenancy_1.tenancy_ref,
          template_id: template_id,
          version: 2,
          message_type: 'email',
          personalisation: { 'first name' => first_name }.to_json
        ).once

      subject
    end

    it 'should call action_diary_usecase' do
      expect(add_action_diary_usecase).to receive(:execute)
      .with(
        user_id: user_id,
        tenancy_ref: tenancy_1.tenancy_ref,
        action_code: 'GME',
        comment: "An email has been sent to '#{recipient}' with template id '#{template_id}'"
      )
      .once

      subject
    end
  end
end
