require 'rails_helper'

describe HackneyCloud::Adapter::AwsS3 do
  subject(:s3) { described_class.new(stub: true) }

  it 'uploads a file on S3' do
    filename = './spec/lib/hackney_cloud/adapter/upload_test.txt'
    new_filename = SecureRandom.uuid

    expect(s3.upload('my-bucket', filename, new_filename)).to be true
  end
end
