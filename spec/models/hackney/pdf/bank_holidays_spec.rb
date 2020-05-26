require 'rails_helper'

RSpec.describe Hackney::PDF::BankHolidays, type: :model do

  before do
    stub_response_body = File.read('spec/lib/hackney/pdf/test_bank_holidays_api_response.txt')
    stub_request(:get, 'https://www.gov.uk/bank-holidays.json').to_return(
      status: 200,
      body: stub_response_body
    )

    Rails.cache.delete('Hackney/PDF/BankHolidays')
  end

  let(:bank_holidays_retriever) { instance_double(Hackney::PDF::BankHolidaysRetriever, execute: nil) }

  it 'makes a call to the retriever when nothing is cached' do
    described_class.dates(bank_holidays_retriever)

    expect(bank_holidays_retriever).to have_received(:execute)
  end

  it 'does not make a call to the retriever when something is cached' do
    described_class.dates(bank_holidays_retriever)
    described_class.dates(bank_holidays_retriever)

    expect(bank_holidays_retriever).to have_received(:execute).once
  end
end
