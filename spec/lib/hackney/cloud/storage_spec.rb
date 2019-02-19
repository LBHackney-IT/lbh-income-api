require 'rails_helper'

describe Hackney::Cloud::Storage, type: :model do
  let(:cloud_adapter_fake) { double(:upload) }
  let(:storage) { described_class.new(cloud_adapter_fake, Hackney::CloudDocument) }

  describe '#upload' do
    it 'saves the file and return the ID' do
      expect(cloud_adapter_fake).to receive(:upload).with('my-bucket', 'my-file', 'new-filename')

      storage.upload('my-bucket', 'my-file', 'new-filename')
    end
  end

  describe '#save' do
    context 'when the file exists' do
      let(:filename) { './spec/lib/hackney/cloud/adapter/upload_test.txt' }

      it 'uploads the file and creates a new entry' do
        expect { storage.save(filename) }.to(change(Hackney::CloudDocument, :count).by(1))

        doc = Hackney::CloudDocument.last

        expect(doc.uuid).not_to be_empty
        expect(doc.extension).to eq('.txt')
        expect(doc.filename).to include('.txt')
        expect(doc.mime_type).to eq('text/plain')
        expect(doc.url).to match(/https:.*#{doc.uuid}#{doc.extension}/)
      end
    end

    context 'when the file DOES NOT exist' do
      let(:filename) { 'non-existent-file.txt' }

      it 'raises and exception AND does not create a new entry in Document' do
        expect { storage.save(filename) }.to raise_exception('No such file: non-existent-file.txt')
      end

      it 'does not create a new entry in Document' do
        expect {
          begin
            storage.save(filename)
          rescue StandardError
            nil
          end
        }.not_to change(Hackney::CloudDocument, :count)
      end
    end
  end
end
