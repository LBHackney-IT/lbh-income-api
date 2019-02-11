require 'rails_helper'

describe HackneyCloud::Storage do
  describe '#save' do
    it 'saves the file and return the ID' do
      cloud_adapter_fake = double(:upload)
      cloud_storage = described_class.new(cloud_adapter_fake)

      expect(cloud_adapter_fake).to receive(:upload).with('my-bucket', 'my-file')

      cloud_storage.save('my-bucket', 'my-file')
    end
  end
end
