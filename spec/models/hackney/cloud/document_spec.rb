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

  describe '#by_payment_ref' do
    it { expect(described_class.by_payment_ref(payment_ref)).to eq([document]) }
  end

  describe '#parsed_metadata' do
    it { expect(document.parsed_metadata).to eq(metadata) }
    it { expect(document.parsed_metadata).to be_a_kind_of(Hash) }
  end

  describe '#income_collection?' do
    it { expect(document.income_collection?).to eq(false) }
  end

  describe '#failed?' do
    it { expect(document.failed?).to eq(false) }
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

    describe '#failed?' do
      it { expect(document.failed?).to eq(true) }
    end

    describe '#income_collection?' do
      it { expect(document.income_collection?).to eq(true) }
    end
  end
end
