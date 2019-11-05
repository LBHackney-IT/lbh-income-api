require 'rails_helper'

describe UseCases::SaveToCache do
  describe '#execute' do
    let(:cache_spy) { spy }
    let(:save_to_cache_use_case) { described_class.new(cache: cache_spy) }

    let(:uuid_stub) { 'abcef-1234' }
    let(:cache_expires_time) { 12.hours }
    let(:dummy_data) { double('DummyData') }

    before do
      allow(SecureRandom).to receive(:uuid).and_return(uuid_stub)
    end

    it 'generates a UUID via SecureRandom' do
      save_to_cache_use_case.execute(data: dummy_data)

      expect(SecureRandom).to have_received(:uuid)
    end

    it 'uses the supplied cache to store the data' do
      expect(cache_spy).to receive(:write).with(uuid_stub, dummy_data, instance_of(Hash))

      save_to_cache_use_case.execute(data: dummy_data)
    end

    it 'sets an expire time on the cache' do
      expect(cache_spy).to receive(:write).with(uuid_stub, dummy_data, expires_in: cache_expires_time)

      save_to_cache_use_case.execute(data: dummy_data)
    end

    it 'returns an UUID' do
      expect(save_to_cache_use_case.execute(data: dummy_data)).to eq(uuid_stub)
    end
  end
end
