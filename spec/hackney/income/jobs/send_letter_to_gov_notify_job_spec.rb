require 'rails_helper'

describe Hackney::Income::Jobs::SendLetterToGovNotifyJob do
  let(:document_id) do
    Hackney::Cloud::Document.create(
      filename: 'test_file.txt',
      extension: '.txt',
      uuid: SecureRandom.uuid,
      mime_type: 'application/pdf',
      metadata: {
        user_id: 123,
        payment_ref: 1_234_567_890
      }.to_json
    ).id
  end

  let(:message_receipt) { Hackney::Notification::Domain::NotificationReceipt.new(body: 'body', message_id: SecureRandom.uuid) }

  before {
    expect_any_instance_of(Aws::S3::Encryption::Client).to receive(:get_object).and_return(AwsClientResponse.new)
    expect_any_instance_of(Hackney::Notification::SendManualPrecompiledLetter).to receive(:execute).and_return(message_receipt)
  }

  it 'updates with message id' do
    doc = Hackney::Cloud::Document.find(document_id)
    expect { described_class.perform_now(document_id: document_id) }.to change { doc.reload.ext_message_id }.from(nil).to(message_receipt.message_id)
  end
end
