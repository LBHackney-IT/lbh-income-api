require 'rails_helper'

describe Hackney::PDF::BankHolidaysRetriever do
  context 'when API request returns a 200' do
    before do
      stub_response_body = File.read(File.dirname(__FILE__) + '/test_bank_holidays_api_response.txt')
      stub_request(:get, 'https://www.gov.uk/bank-holidays.json').to_return(
        status: 200,
        body: stub_response_body
      )
    end

    it 'returns list of bank holiday dates' do
      bank_holidays = described_class.new.execute
      expect(bank_holidays.length).to eq(56)
      expect(bank_holidays.include?('2020-05-08')).to eq(true)
      expect(bank_holidays.include?('2021-05-03')).to eq(true)
      expect(bank_holidays.include?('2019-12-25')).to eq(true)
      expect(bank_holidays.include?('2020-12-25')).to eq(true)
      expect(bank_holidays.include?('2021-12-27')).to eq(true)
    end
  end

  # context 'when API request does not return 200' do
  #   before do
  #     stub_request(:get, 'https://www.gov.uk/bank-holidays.json').to_return(
  #       status: 500,
  #       body: nil
  #     )
  #   end
  #
  #   it 'raises an UnsuccessfulRetrievalError' do
  #     expect { bank_holidays = described_class.new.execute } .to raise_error(StandardError, /Retrieval Failed/)
  #   end
  # end

  context 'when API request responds with 200 but body is empty' do
    it 'returns an empty array if body is an empty hash' do
      stub_request(:get, 'https://www.gov.uk/bank-holidays.json').to_return(
        status: 200,
        body: '{}'
      )

      bank_holidays = described_class.new.execute
      expect(bank_holidays).to eq([])
    end
  end
end
