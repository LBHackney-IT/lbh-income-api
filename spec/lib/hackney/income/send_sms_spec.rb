require 'rails_helper'

describe Hackney::Income::SendSms do
  let(:tenancy) { create_tenancy_model }
  let(:notification_gateway) { Hackney::Income::StubNotificationsGateway.new }
  let(:add_action_diary_usecase) { double(Hackney::Tenancy::AddActionDiaryEntry) }

  before do
    tenancy.save
  end

  let(:send_sms) do
    described_class.new(
      notification_gateway: notification_gateway,
      add_action_diary_usecase: add_action_diary_usecase
    )
  end

  context 'when sending an SMS manually' do
    let(:template_id) { Faker::Superhero.power }
    let(:phone_number) { Faker::Number.leading_zero_number(11) }
    let(:reference) { Faker::Superhero.prefix }
    let(:first_name) { Faker::Superhero.name }
    let(:user_id) { Faker::Number.number(2) }

    before do
      allow(add_action_diary_usecase).to receive(:execute)
    end

    subject do
      send_sms.execute(
        user_id: user_id,
        tenancy_ref: tenancy.tenancy_ref,
        template_id: template_id,
        phone_number: phone_number,
        reference: reference,
        variables: { 'first name' => first_name }
      )
      notification_gateway.last_text_message
    end

    alias_method :send_sms_message, :subject

    it 'should map the tenancy to a set of variables' do
      expect(subject).to include(
        variables: include(
          'first name' => first_name
        )
      )
    end

    it 'should pass through the phone number' do
      expect(subject).to include(
        phone_number: phone_number
      )
    end

    it 'should pass through the template id' do
      expect(subject).to include(
        template_id: template_id
      )
    end

    it 'should generate a tenant and message representative reference' do
      expect(subject).to include(
        reference: reference
      )
    end

    xit 'should write a entry to the action diary' do
      expect(add_action_diary_usecase).to receive(:execute)
      .with(
        user_id: user_id,
        tenancy_ref: tenancy.tenancy_ref,
        action_code: '', # TODO: this needs to be decided
        action_balance: nil, # TODO: this should not be required
        comment: "An SMS has been sent to '#{phone_number}'"
      )
      .once

      subject
    end
  end
end
