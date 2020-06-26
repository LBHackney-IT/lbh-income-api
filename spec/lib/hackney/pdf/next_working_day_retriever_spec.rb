require 'rails_helper'

describe Hackney::PDF::NextWorkingDayRetriever do
  before do
    stub_response_body = File.read('spec/lib/hackney/pdf/test_bank_holidays_api_response.txt')
    stub_request(:get, 'https://www.gov.uk/bank-holidays.json').to_return(
      status: 200,
      body: stub_response_body
    )

    Rails.cache.delete('Hackney/PDF/BankHolidays')
  end

  context 'when API request returns a 200' do
    it 'returns the next working day' do
      Timecop.freeze(2020, 5, 22)
      next_working_day = described_class.new.execute
      expect(next_working_day).to eq('26 May 2020')
      Timecop.return
    end

    it 'makes a call to the Bank Holidays API when nothing is cached' do
      next_working_day_retriever = described_class.new
      expect(next_working_day_retriever).to receive(:get_bank_holidays).and_call_original
      next_working_day_retriever.execute
    end

    it 'does not make a call to the Bank Holidays API when something is cached' do
      next_working_day_retriever = described_class.new
      expect(next_working_day_retriever).to receive(:get_bank_holidays).once.and_call_original
      next_working_day_retriever.execute
      next_working_day_retriever.execute
    end
  end

  context 'when tomorrow is the next working day' do
    it "returns tomorrow's date" do
      Timecop.freeze(2020, 6, 25)
      next_working_day = described_class.new.execute
      expect(next_working_day).to eq('26 June 2020')
      Timecop.return
    end
  end

  context 'when tomorrow is a Saturday and the following Monday is a working day' do
    it "returns Monday's date" do
      Timecop.freeze(2020, 6, 26)
      next_working_day = described_class.new.execute
      expect(next_working_day).to eq('29 June 2020')
      Timecop.return
    end
  end

  context 'when tomorrow is a Saturday and the following Monday is a bank holiday' do
    it "returns Tuesday's date" do
      Timecop.freeze(2020, 5, 22)
      next_working_day = described_class.new.execute
      expect(next_working_day).to eq('26 May 2020')
      Timecop.return
    end
  end

  context 'when tomorrow is a bank holiday Friday and the following Monday is a working day' do
    it "returns Monday's date" do
      Timecop.freeze(2020, 5, 7)
      next_working_day = described_class.new.execute
      expect(next_working_day).to eq('11 May 2020')
      Timecop.return
    end
  end

  context 'when Bank Holidays API request does not return 200' do
    before do
      stub_request(:get, 'https://www.gov.uk/bank-holidays.json').to_return(
        status: 500,
        body: nil
      )

      Rails.cache.delete('Hackney/PDF/BankHolidays')
    end

    it 'raises an UnsuccessfulRetrievalError' do
      expect { described_class.new.execute } .to raise_error(StandardError, /Retrieval Failed/)
    end
  end

  context 'when Bank Holidays API request responds with 200 but body is empty' do
    it "returns tomorrow's date" do
      stub_request(:get, 'https://www.gov.uk/bank-holidays.json').to_return(
        status: 200,
        body: '{}'
      )
      Rails.cache.delete('Hackney/PDF/BankHolidays')

      Timecop.freeze(2020, 6, 25)
      next_working_day = described_class.new.execute
      expect(next_working_day).to eq('26 June 2020')
      Timecop.return
    end
  end
end
