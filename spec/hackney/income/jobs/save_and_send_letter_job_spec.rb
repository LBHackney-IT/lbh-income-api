require 'rails_helper'

describe Hackney::Income::Jobs::SaveAndSendLetterJob do
  include ActiveJob::TestHelper

  let(:pdf_file) { File.open('spec/test_files/test_pdf.pdf', 'rb') }
  # let(:stringio) { StringIO.new(file.read)}
  let(:file_name) { 'test_pdf.pdf' }
  let(:bucket_name) { 'my-bucket' }
  let(:letter_html) { "<h1>#{Faker::RickAndMorty.quote}</h1>" }
  let(:uuid) { SecureRandom.uuid }
  let(:doc) { create(:document, filename: 'my-doc.pdf') }

  let(:enqueue_save_send) {
    described_class.perform_now(bucket_name: bucket_name,
                                filename: file_name,
                                letter_html: letter_html,
                                document_id: doc.id)
  }
  let(:message_receipt) { Hackney::Notification::Domain::NotificationReceipt.new(body: 'body', message_id: SecureRandom.uuid) }

  before {
    expect_any_instance_of(Aws::S3::Encryption::Client).to receive(:put_object).and_return(AwsEncryptionClientDouble.new(nil).send(:put_object))
  }

  it 'uploads to clouds' do
    expect_any_instance_of(Aws::S3::Encryption::Client).to receive(:get_object).and_return(AwsClientResponse.new)
    # expect_any_instance_of(Hackney::Notification::GovNotifyGateway).to receive(:send_precompiled_letter).once

    expect_any_instance_of(Hackney::Notification::SendManualPrecompiledLetter).to receive(:execute).and_return(message_receipt)

    enqueue_save_send
    uploaded_doc = Hackney::Cloud::Document.find(doc.id)
    expect(uploaded_doc.url).to eq 'blah.com'
    expect(uploaded_doc.status).to eq('uploaded')
  end

  it 'perform_now on SendLetterToGovNotifyJob' do
    expect_any_instance_of(Hackney::Income::Jobs::SendLetterToGovNotifyJob).to receive(:perform_now).once
    enqueue_save_send
  end

  it 'creates pdf' do
    # expect_any_instance_of(Aws::S3::Encryption::Client).to receive(:put_object).and_return(AwsEncryptionClientDouble.new(nil).send(:put_object))
    expect_any_instance_of(Aws::S3::Encryption::Client).to receive(:get_object).and_return(AwsClientResponse.new)
    expect_any_instance_of(Hackney::Notification::SendManualPrecompiledLetter).to receive(:execute).and_return(message_receipt)

    allow(File).to receive(:delete)
    expect_any_instance_of(Hackney::PDF::Generator).to receive(:execute).with(letter_html).and_return(FakePDFKit.new(pdf_file))
    # expect(Hackney::PDF::Generator.new).to receive(:execute).with(letter_html) # .and_return(FakePDFKit.new(pdf_file))
    enqueue_save_send
  end
end

class FakePDFKit
  def initialize(return_file)
    @return_file = return_file
  end

  def to_file(html)
    @return_file
  end
end
