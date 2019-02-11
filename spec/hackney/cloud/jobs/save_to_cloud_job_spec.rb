require 'rails_helper'

describe Hackney::Cloud::Jobs::SaveToCloudJob do
  subject { described_class }

  let(:uuid) { SecureRandom.uuid }

  it 'uploads to clouds' do
    Hackney::Cloud::Document.create(filename: 'my-doc.pdf', uuid: uuid)

    subject.perform_now(bucket_name: 'my-bucket',
                        filename: 'my-doc.pdf',
                        new_filename: "#{uuid}.pdf",
                        model_document: 'Hackney::Cloud::Document',
                        uuid: uuid)

    uploaded_doc = Hackney::Cloud::Document.find_by(uuid: uuid)

    expect(uploaded_doc.url).to match(/https:.*#{uuid}\.pdf/)
    expect(uploaded_doc.status).to eq('uploaded')
  end
end
