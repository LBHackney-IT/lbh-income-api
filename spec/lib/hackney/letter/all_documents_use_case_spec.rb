require 'rails_helper'

describe Hackney::Letter::AllDocumentsUseCase do
  subject(:all_documents_use_case) { described_class.new(cloud_storage: storage) }

  let(:cloud_adapter_fake) { double(:upload) }
  let(:storage) { Hackney::Cloud::Storage.new(cloud_adapter_fake, Hackney::Cloud::Document) }

  let(:username) { Faker::Name.name }

  before do
    create(:document, username: username, status: :received)
    create(:document, username: username, status: :accepted)
  end

  it 'parses and populates metadata accordingly' do
    documents = all_documents_use_case.execute.documents

    documents.each do |document|
      expect(document.metadata).to include(username)
    end
  end
end
