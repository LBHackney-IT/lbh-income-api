require 'rails_helper'

describe Hackney::Cloud::Adapter::AwsS3 do
  subject(:s3) { described_class.new(stub: true) }

  let(:filename) { './spec/lib/hackney/cloud/adapter/upload_test.txt' }
  let(:new_filename) { SecureRandom.uuid }

  it 'uploads a file on S3' do
    s3_url = s3.upload('my-bucket', filename, new_filename)

    expect(s3_url).to match `https:\/\/my-bucket.*#{new_filename}`
  end
end
