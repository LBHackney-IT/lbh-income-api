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

  describe 'retrieve all document' do
    let!(:uploaded) { create(:document, status: :uploaded) }

    before do
      create(:document, status: :uploading)
      create(:document, status: :received)
      create(:document, status: :accepted)
      create(:document, status: :downloaded)
      create(:document, status: :queued)
    end

    it 'retrieves all documents except for the one marked as "uploaded"' do
      expect(storage.all_documents).not_to include(uploaded)
    end

    context 'when payment_ref param is used' do
      subject { storage.all_documents(payment_ref: payment_ref_param) }

      let(:payment_ref) { Faker::Number.number(10) }
      let!(:uploaded_document) { create(:document, status: :uploaded, metadata: { payment_ref: payment_ref }.to_json) }
      let!(:downloaded_document) { create(:document, status: :downloaded, metadata: { payment_ref: payment_ref }.to_json) }
      let!(:accepted_document) { create(:document, status: :accepted, metadata: { payment_ref: payment_ref }.to_json) }

      context 'when payment_ref exists' do
        let(:payment_ref_param) { payment_ref }

        it { is_expected.to include(downloaded_document) }
        it { is_expected.to include(accepted_document) }
        it { is_expected.not_to include(uploaded_document) }
      end

      context 'when payment_ref does not exist' do
        let(:payment_ref_param) { 'NON-EXISTENT-PAYMENT-REF' }

        it { is_expected.not_to include([downloaded_document, uploaded_document, accepted_document]) }
      end
    end
  end

  describe '#save' do
    context 'when the file exists' do
      let(:file) { File.open('spec/test_files/test_pdf.pdf', 'rb') }
      let(:filename) { File.basename(file) }
      let(:uuid) { SecureRandom.uuid }
      let(:metadata) { { bunnies: true } }
      let(:letter_html) { "<h1>#{Faker::RickAndMorty.quote}</h1>" }

      it 'creates a new entry' do
        expect { storage.save(letter_html: letter_html, uuid: uuid, filename: filename, metadata: metadata) }.to(change(Hackney::Cloud::Document, :count).by(1))

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
          storage.save(letter_html: letter_html, uuid: uuid, filename: filename, metadata: metadata)
        }.to(have_enqueued_job(Hackney::Income::Jobs::SaveAndSendLetterJob).with { |params|
          file.rewind
          expect(params[:bucket_name]).to eq 'hackney-docs-test'
          expect(params[:filename]).to eq File.basename(file)
          expect(params[:document_id]).not_to be_nil
          expect(params[:letter_html]).to eq letter_html
        })
      end
    end

    describe '#read_document' do
      let(:document) { create(:document) }

      context 'when the file exists' do
        it 'retrieves the content' do
          uuid = document.uuid

          expect(cloud_adapter_fake).to receive(:download)
            .with(bucket_name: 'hackney-docs-test', filename: "#{uuid}.pdf")
            .and_return(double(:tempfile, path: '/tmp/tempfile'))

          expect(storage.read_document(document.id)[:filepath]).to eq('/tmp/tempfile')
        end
      end
    end

    describe '#update_document_status' do
      let(:document) { create(:document) }
      let(:status) { %i[received accepted downloaded queued failure_reviewed].sample }

      it 'status is updated' do
        updated_document = storage.update_document_status(document: document, status: status)

        expect(updated_document.status).to eq(status.to_s)
      end

      context 'when status is failed' do
        let(:status) { 'validation-failed' }

        it 'raises Sentry notification' do
          expect(Raven).to receive(:send_event)

          updated_document = storage.update_document_status(document: document, status: status)

          expect(updated_document.status).to eq(status)
        end
      end
    end
  end
end
