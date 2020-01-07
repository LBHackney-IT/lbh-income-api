require 'rails_helper'

describe Hackney::Cloud::Document do
  before {
    described_class.delete_all
  }

  let(:payment_ref) { Faker::Number.number(10) }

  let(:status) { :downloaded }

  let(:template) {
    {
      path: 'path/to/template.erb',
      name: 'Test template',
      id: 'test_template'
    }
  }

  let(:metadata) {
    {
      payment_ref: payment_ref,
      template: template
    }
  }

  let(:document) { create(:document, status: status, metadata: metadata.to_json) }

  it '#find_by_payment_ref' do
    expect(described_class.find_by_payment_ref(payment_ref)).to eq([document])
  end

  it '#parsed_metadata' do
    expect(document.parsed_metadata).to eq(metadata)
  end

  it '#income_collection?' do
    expect(document.income_collection?).to eq(false)
  end

  it '#failed?' do
    expect(document.failed?).to eq(false)
  end

  context 'when there is a failed income collection letter saved' do
    let(:template) {
      {
        path: 'lib/hackney/pdf/templates/income/income_collection_letter_1.erb',
        name: 'Income collection letter 1',
        id: 'income_collection_letter_1'
      }
    }

    let(:status) { :'validation-failed' }

    it '#failed?' do
      expect(document.failed?).to eq(true)
    end

    it '#income_collection?' do
      expect(document.income_collection?).to eq(true)
    end
  end
end
