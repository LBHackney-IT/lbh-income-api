require 'rails_helper'

describe Hackney::PDF::Generator do
  let(:gateway) { described_class.new }
  let(:html) { "<h1>#{Faker::RickAndMorty.quote}</h1>" }

  context 'when generating a pdf' do
    subject do
      gateway.execute(html)
    end

    let(:source) { subject.source.instance_values['source'] }

    it 'is a pdfkit' do
      expect(subject).to be_a PDFKit
    end

    it 'pdf has the right source' do
      expect(source).to eq(html)
    end

    it 'pdf should have the right options' do
      expect(subject.options).to eq(
        '--quiet' => nil,
        '--page-size' => 'A4',
        '--margin-top' => '0.19685in',
        '--margin-right' => '0.590551in',
        '--margin-bottom' => '0.23000in',
        '--margin-left' => '0.590551in',
        '--encoding' => 'UTF-8'
      )
    end
  end
end
