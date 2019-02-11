require 'rails_helper'

describe Hackney::Cloud::Storage, type: :model do
  let(:cloud_adapter_fake) { double(:upload) }
  let(:storage) { described_class.new(cloud_adapter_fake, Hackney::Cloud::Document) }

  describe '#upload' do
    it 'saves the file and return the ID' do
      expect(cloud_adapter_fake).to receive(:upload).with('my-bucket', 'my-file', 'new-filename')

      storage.upload('my-bucket', 'my-file', 'new-filename')
    end
  end

  describe '#save' do
    context 'when the file exists' do
      before { ActiveJob::Base.queue_adapter = :test }

      let(:filename) { './spec/lib/hackney/cloud/adapter/upload_test.txt' }

      it 'creates a new entry' do
        expect { storage.save(filename) }.to(change(Hackney::Cloud::Document, :count).by(1))

        doc = Hackney::Cloud::Document.last

        expect(doc.uuid).not_to be_empty
        expect(doc.extension).to eq('.txt')
        expect(doc.filename).to include('.txt')
        expect(doc.mime_type).to eq('text/plain')
        expect(doc.status).to eq 'uploading'
      end

      it 'enqueues the job to save the file to the cloud' do
        expect {
          storage.save(filename)
        }.to(have_enqueued_job.with { |params|
          expect(params[:bucket_name]).to eq 'hackney-docs-test'
          expect(params[:filename]).to eq './spec/lib/hackney/cloud/adapter/upload_test.txt'
          expect(params[:model_document]).to eq 'Hackney::Cloud::Document'
          expect(params[:uuid]).not_to be_nil
          expect(params[:new_filename]).to include('.txt')
        })
      end
    end

    context 'when the file DOES NOT exist' do
      let(:filename) { 'non-existent-file.txt' }

      it 'raises an exception AND does not create a new entry in Cloud::Document' do
        expect { storage.save(filename) }.to raise_exception('No such file: non-existent-file.txt')
      end

      it 'does not create a new entry in Cloud::Document' do
        expect {
          begin
            storage.save(filename)
          rescue StandardError
            nil
          end
        }.not_to change(Hackney::Cloud::Document, :count)
      end
    end
  end
end
