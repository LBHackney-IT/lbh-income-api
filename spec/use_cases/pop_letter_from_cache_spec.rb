require 'rails_helper'

describe UseCases::PopLetterFromCache do
  subject { described_class.new(cache: mock_cache) }

  let(:uuid) { Faker::Number.number(5) }

  describe 'asks the cache for the right ID' do
    let(:mock_cache) do
      mock_cache = double
      allow(mock_cache).to receive(:read).with(uuid).and_return('letter-data')
      allow(mock_cache).to receive(:delete)
      mock_cache
    end

    it 'works' do
      result = subject.execute(uuid: uuid)
      expect(result).to eq('letter-data')
    end
  end

  describe 'deletes the retrieved letter from the cache' do
    let(:mock_cache) { spy(:delete) }

    it 'works' do
      subject.execute(uuid: uuid)
      expect(mock_cache).to have_received(:delete).with(uuid)
    end
  end
end
