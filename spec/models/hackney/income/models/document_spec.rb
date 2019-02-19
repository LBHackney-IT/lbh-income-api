require 'rails_helper'

RSpec.describe Hackney::Income::Models::Document, type: :model do
  describe 'attributes' do
    subject { described_class.new.attributes }

    it { is_expected.to include('uuid', 'filename', 'format', 'metadata', 'created_at') }
  end

  describe '#cloud_save' do
    subject(:Document) { described_class }

    context 'when the file exists' do
      let(:filename) { './spec/lib/hackney_cloud/adapter/upload_test.txt' }

      it 'create a new entry containing uuid' do
        expect { Document.cloud_save(filename) }.to(change(described_class, :count).by(1))

        doc = Document.last

        expect(doc.uuid).not_to be_empty
        expect(doc.format).to eq('.txt')
        expect(doc.filename).to include('.txt')
        expect(doc.mime_type).to eq('text/plain')
        expect(doc.url).to match /https:.*#{doc.uuid}#{doc.format}/
      end
    end

    context 'when the file DOES NOT exist' do
      let(:filename) { 'non-existent-file.txt' }

      it 'raises and exception AND does not create a new entry in Document' do
        expect { Document.cloud_save(filename) }.to raise_exception('No such file: non-existent-file.txt')
      end

      it 'does not create a new entry in Document' do
        expect {
          begin
            Document.cloud_save(filename)
          rescue StandardError
            nil
          end
        }.not_to change(Document, :count)
      end
    end
  end
end
