require 'rails_helper'

describe UseCases::GeneratePdf do
  subject { described_class.new }

  let(:uuid) { Faker::Lorem.characters(5) }
  let(:letter_html) { 'some_html_data' }

  context 'with the uuid and letter_html' do
    it 'generates a pdf file' do
      result = subject.execute(uuid: uuid, letter_html: letter_html)

      # reading the PDF is a little slow here,
      # maybe push up to acceptance spec?
      pdf_content = PDF::Reader.new(result).pages.map(&:text).join

      expect(pdf_content).to include(letter_html)
    end

    it 'does not change the input html' do
      original_input = 'original'
      subject.execute(uuid: uuid, letter_html: original_input)

      expect(original_input).to eq('original')
    end
  end
end
