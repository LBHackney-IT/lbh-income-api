require 'rails_helper'

describe Hackney::Income::Jobs::SendGreenInArrearsMsgJob do
  subject { described_class }

  let(:mock_automated_message) { instance_double(Hackney::Income::SendAutomatedMessageToTenancy) }
  let(:mock_automated_message_class) { class_double(Hackney::Income::SendAutomatedMessageToTenancy) }
  let(:tenancy_ref) { Faker::Internet.slug }
  let(:balance) { Faker::Commerce.price(100.0..199.99) }
  let(:case_id) { Faker::Number.number }

  before do
    stub_const('Hackney::Income::GovNotifyGateway', Hackney::Income::DummyGovNotifyGateway)
    stub_const('Hackney::Income::SendAutomatedMessageToTenancy', mock_automated_message_class)
    allow(mock_automated_message_class).to receive(:new).and_return(mock_automated_message)

    create(:case_priority, balance: balance, tenancy_ref: tenancy_ref, case_id: case_id)
  end

  it 'calls usecase with correct args' do
    expect(mock_automated_message).to receive(:execute).with(
      hash_including(
        tenancy_ref: tenancy_ref,
        sms_template_id: Rails.configuration.x.green_in_arrears.sms_template_id,
        email_template_id: Rails.configuration.x.green_in_arrears.email_template_id,
        variables: { balance: balance }
      )
    ).once
    subject.perform_now(case_id: case_id)
  end

  it 'no message is sent if case_priority not found' do
    expect(mock_automated_message).not_to receive(:execute)
    expect { subject.perform_now(case_id: 123_456_789_087_654_321) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'is able to be scheduled' do
    expect do
      subject.set(wait_until: Time.now + 5.minutes).perform_later
    end.not_to raise_error
  end
end
