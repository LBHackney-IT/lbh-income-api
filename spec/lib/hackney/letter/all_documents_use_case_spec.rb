require 'rails_helper'

describe Hackney::Letter::AllDocumentsUseCase do
  subject(:all_documents_use_case) { described_class.new(cloud_storage: storage) }

  let(:cloud_adapter_fake) { double(:upload) }
  let(:storage) { Hackney::Cloud::Storage.new(cloud_adapter_fake, Hackney::Cloud::Document) }

  let(:username) { Faker::Name.name }

  let(:page_number) { 1 }
  let(:documents_per_page) { 10 }
  let(:payment_ref) { Faker::Number.number(10) }
  let(:document_status) { Hackney::Cloud::Document.statuses.keys.sample }

  before do
    create(:document, username: username, status: :received)
    create(:document, username: username, status: :accepted)
  end

  it 'passes parameters correctly to the gateway' do
    expect(storage).to receive(:all_documents).with(
      payment_ref: payment_ref,
      status: document_status,
      page_number: page_number,
      documents_per_page: documents_per_page
    ).and_call_original

    all_documents_use_case.execute(
      payment_ref: payment_ref,
      status: document_status,
      page_number: page_number,
      documents_per_page: documents_per_page
    )
  end

  it 'parses and populates metadata accordingly' do
    documents = all_documents_use_case.execute.documents

    documents.each do |document|
      expect(document.metadata).to include(username)
    end
  end
end
