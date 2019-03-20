require 'rails_helper'

describe Hackney::Cloud::Storage, type: :model do
  let(:cloud_adapter_fake) { double(:upload) }
  let(:storage) { described_class.new(cloud_adapter_fake, Hackney::Cloud::Document) }

  describe '#upload' do
    it 'saves the file and return the ID' do
      expect(cloud_adapter_fake).to receive(:upload).with(bucket_name: 'my-bucket', content: 'my-file', filename: 'new-filename')

      storage.upload('my-bucket', 'my-file', 'new-filename')
    end
  end

  describe '#save' do
    context 'when the file exists' do
      before { ActiveJob::Base.queue_adapter = :test }

      let(:file) { File.open('spec/test_files/test_pdf.pdf', 'rb') }
      let(:uuid) { SecureRandom.uuid }
      let(:metadata) { {bunnies: true} }

      it 'creates a new entry' do
        expect { storage.save(file: file, uuid: uuid, metadata: metadata) }.to(change(Hackney::Cloud::Document, :count).by(1))

        doc = Hackney::Cloud::Document.last

        expect(doc.uuid).not_to be_empty
        expect(doc.extension).to eq File.extname(file)
        expect(doc.filename).to eq File.basename(file)
        expect(doc.mime_type).to eq('application/pdf')
        expect(doc.status).to eq 'uploading'
        expect(doc.metadata).to eq metadata.to_json
      end

      it 'enqueues the job to save the file to the cloud' do
        expect {
          storage.save(file: file, uuid: uuid, metadata: metadata)
        }.to(have_enqueued_job.with { |params|
          file.rewind
          expect(params[:bucket_name]).to eq 'hackney-docs-test'
          expect(params[:filename]).to eq File.basename(file)
          expect(params[:document_id]).not_to be_nil
          expect(params[:content]).to eq file.read
        })
      end
    end

  end
end
