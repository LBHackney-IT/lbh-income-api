require 'rails_helper'

describe UseCases::UpdateDocumentS3Url do
  subject { described_class.new }

  context 'with letter data and bucket name' do
    let(:document_data) { { url: 'aws_s3_url' } }

    let(:document_model) do
      Hackney::Cloud::Document.create(
        filename: 'test_file.txt',
        extension: '.txt',
        uuid: SecureRandom.uuid,
        mime_type: 'application/pdf',
        url: nil,
        status: 'uploading',
        metadata: {
          user_id: 123,
          payment_ref: 1_234_567_890
        }.to_json
      )
    end

    it 'calls update on the model' do
      subject.execute(document_data: document_data, document_model: document_model)

      expect(document_model.status).to eq('uploaded')
      expect(document_model.url).to eq('aws_s3_url')
    end
  end
end
