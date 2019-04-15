require 'rails_helper'

describe DocumentsController do
  describe '#download' do
    let(:template_id) { Faker::Demographic.demonym }
    let(:payment_ref) { Faker::Number.number(10) }

    let(:metadata) { { template_id: template_id, payment_ref: payment_ref }.to_json }
    let(:document) { create(:document, metadata: metadata) }
    let(:filename) { payment_ref + '_' + template_id + document.extension }

    let(:download_use_case) { Hackney::Letter::DownloadUseCase }

    context 'when the document is present' do
      before do
        expect_any_instance_of(download_use_case)
          .to receive(:execute).with(id: document.id.to_s)
                               .and_return(filepath: Tempfile.new.path, document: document)
        get :download, params: { id: document.id }
      end

      it { expect(response).to be_successful }
      it { expect(response.header['Content-Disposition']).to eq("attachment; filename=\"#{filename}\"") }
      it { expect(response.content_type).to eq document.mime_type }
    end
  end

  describe '#index' do
    it 'returns all documents' do
      expect_any_instance_of(Hackney::Letter::AllDocumentsUseCase)
        .to receive(:execute)

      get :index
    end
  end
end
