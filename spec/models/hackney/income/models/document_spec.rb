require 'rails_helper'

RSpec.describe Hackney::Income::Models::Document, type: :model do
  describe 'attributes' do
    subject { described_class.new.attributes }

    it { is_expected.to include('uuid', 'filename', 'format', 'metadata', 'created_at') }
  end

  describe '#cloud_save' do
    subject(:Document) { described_class }

    context 'when filename is NIL' do
      it 'expect to NOT create a new entry' do
        expect(Rails.configuration.cloud_storage).not_to receive(:save)
        expect { Document.cloud_save('') }.not_to(change(Document, :count))
      end
    end

    context 'when the document exists' do
      it 'create a new entry containing uuid' do

        filename = 'my-doc.txt'

        expect(Rails.configuration.cloud_storage).to receive(:save)

        expect { Document.cloud_save(filename) }.to(change(described_class, :count).by(1))

        doc = Document.last
        expect(doc.uuid).not_to be_empty
        expect(doc.format).to eq('.txt')
        expect(doc.filename).to include('.txt')
        expect(doc.mime_type).to eq('text/plain')
      end
    end
  end
end
