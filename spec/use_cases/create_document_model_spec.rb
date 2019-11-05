require 'rails_helper'

describe UseCases::CreateDocumentModel do
  subject { described_class.new(Hackney::Cloud::Document) }

  context 'when saving the document model' do
    let(:file) { File.open('spec/test_files/test_pdf.pdf', 'rb') }
    let(:filename) { File.basename(file) }
    let(:uuid) { SecureRandom.uuid }
    let(:metadata) { { data: true } }
    let(:letter_html) { "<h1>#{Faker::RickAndMorty.quote}</h1>" }

    it 'adds it to the database' do
      expect {
        subject.execute(letter_html: letter_html, uuid: uuid, filename: filename, metadata: metadata)
      }.to change { Hackney::Cloud::Document.count }.by(1)
    end
  end
end
