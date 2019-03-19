require 'rails_helper'
require './lib/hackney/cloud/encryption_client'

describe Hackney::Cloud::EncryptionClient do
  let(:kms_double) { double }

  it 'returns a new Encryption client' do
    allow(Aws::KMS::Client).to receive(:new).and_return(kms_double)

    expect(Aws::S3::Encryption::Client).to receive(:new).with(kms_key_id: '123', kms_client: kms_double)

    described_class.new('123').create
  end
end
