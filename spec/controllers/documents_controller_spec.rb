require 'rails_helper'

describe DocumentsController do
  let(:page_number) { 1 }
  let(:documents_per_page) { 10 }

  describe '#index' do
    it 'returns all documents' do
      expect_any_instance_of(Hackney::Letter::AllDocumentsUseCase)
        .to receive(:execute).with(
          payment_ref: nil,
          status: nil,
          page_number: 1,
          documents_per_page: 20
        )

      get :index
    end

    context 'when the payment_ref param is present' do
      let(:payment_ref) { Faker::Number.number(10) }

      it 'returns all documents filtered by payment_ref' do
        expect_any_instance_of(Hackney::Letter::AllDocumentsUseCase)
          .to receive(:execute).with(
            status: nil,
            payment_ref: payment_ref,
            page_number: page_number,
            documents_per_page: documents_per_page
          )

        get :index, params: { payment_ref: payment_ref, page_number: page_number, documents_per_page: documents_per_page }
      end
    end

    context 'when filtering by status' do
      let(:document_status) { Hackney::Cloud::Document.statuses.keys.sample }

      it 'returns all documents filtered by payment_ref' do
        expect_any_instance_of(Hackney::Letter::AllDocumentsUseCase)
          .to receive(:execute).with(
            status: document_status,
            payment_ref: nil,
            page_number: page_number,
            documents_per_page: documents_per_page
          )

        get :index, params: { status: document_status, page_number: page_number, documents_per_page: documents_per_page }
      end
    end
  end

  describe '#review_failure' do
    let(:document_id) { Faker::Number.number(3) }

    it 'correct usecase is called' do
      expect_any_instance_of(Hackney::Letter::ReviewFailure)
        .to receive(:execute).with(document_id: document_id)

      post :review_failure, params: { id: document_id }
    end
  end
end
