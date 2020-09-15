require 'rails_helper'

describe Hackney::Income::MigrateUhEvictionDate do
  subject(:migrator) {
    described_class.new(
      create_eviction_date: create_eviction_date,
      view_eviction_dates: view_eviction_dates
    ).migrate(criteria)
  }

  let(:create_eviction_date) { double }
  let(:view_eviction_dates) { double }

  let(:criteria) { Stubs::StubCriteria.new(criteria_attributes) }
  let(:existing_eviction_dates) { [] }

  before do
    allow(view_eviction_dates).to receive(:execute).and_return(existing_eviction_dates)
    allow(create_eviction_date).to receive(:execute)
  end

  UH_NIL_DATE = DateTime.parse('1900-01-01 00:00:00')

  context 'when there is no existing eviction date' do
    let(:criteria_attributes) {
      {
        eviction_date: UH_NIL_DATE
      }
    }

    it 'does not create a eviction date' do
      expect(create_eviction_date).not_to receive(:execute)
      subject
    end
  end

  context 'when there are multiple eviction dates in MA' do
    let(:existing_eviction_dates) {
      [
        OpenStruct.new(eviction_date: DateTime.now.midnight - 1.month),
        OpenStruct.new(eviction_date: DateTime.now.midnight - 7.days)
      ]
    }

    context 'when provided newer eviction date' do
      let(:criteria_attributes) {
        {
          eviction_date: DateTime.now.midnight
        }
      }

      it 'creates a new eviction date' do
        expect(create_eviction_date).to receive(:execute)
        subject
      end
    end

    context 'when provided older eviction date' do
      let(:criteria_attributes) {
        {
          eviction_date: DateTime.now.midnight - 3.month
        }
      }

      it 'creates a new eviction date' do
        expect(create_eviction_date).not_to receive(:execute)
        subject
      end
    end
  end
end
