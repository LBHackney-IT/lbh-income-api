require 'rails_helper'

describe Hackney::Income::MigrateUhEviction do
  subject(:migrator) {
    described_class.new(
      create_eviction: create_eviction,
      view_evictions: view_evictions
    ).migrate(criteria)
  }

  let(:create_eviction) { double }
  let(:view_evictions) { double }

  let(:criteria) { Stubs::StubCriteria.new(criteria_attributes) }
  let(:existing_evictions) { [] }

  before do
    allow(view_evictions).to receive(:execute).and_return(existing_evictions)
    allow(create_eviction).to receive(:execute)
  end

  UH_NIL_DATE = DateTime.parse('1900-01-01 00:00:00')

  context 'when there is no existing eviction' do
    let(:criteria_attributes) {
      {
        date: UH_NIL_DATE
      }
    }

    it 'does not create a eviction' do
      expect(create_eviction).not_to receive(:execute)
      subject
    end
  end

  context 'when there are multiple evictions in MA' do
    let(:existing_evictions) {
      [
        OpenStruct.new(eviction_date: DateTime.now.midnight - 1.month),
        OpenStruct.new(eviction_date: DateTime.now.midnight - 7.days)
      ]
    }

    context 'when provided newer eviction' do
      let(:criteria_attributes) {
        {
          eviction_date: DateTime.now.midnight
        }
      }

      it 'creates a new eviction' do
        expect(create_eviction).to receive(:execute).with(
          eviction_params: {
            tenancy_ref: criteria.tenancy_ref,
            date: criteria_attributes[:eviction_date]
          }
        )
        subject
      end
    end

    context 'when provided older eviction' do
      let(:criteria_attributes) {
        {
          eviction_date: DateTime.now.midnight - 3.month
        }
      }

      it 'creates a new eviction' do
        expect(create_eviction).not_to receive(:execute)
        subject
      end
    end
  end
end
