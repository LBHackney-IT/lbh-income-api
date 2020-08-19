require 'rails_helper'

describe Hackney::Income::MigrateUhCourtCase do
  subject(:migrator) { described_class.new(create_court_case: create_court_case).migrate(criteria) }

  let(:create_court_case) { double(Hackney::Income::CreateCourtCase) }

  let(:criteria) { Stubs::StubCriteria.new(criteria_attributes) }

  context 'when there is no existing court case' do
    context 'when provided a criteria without a court date or court outcome' do
      let(:criteria_attributes) {
        {
          court_outcome: nil,
          courtdate: nil
        }
      }

      it 'does not create a court case' do
        expect(create_court_case).not_to receive(:execute)
        subject
      end
    end

    context 'when provided a criteria with a court date but without a court outcome' do
      let(:criteria_attributes) {
        {
          court_outcome: nil,
          courtdate: DateTime.now.midnight - 7.days
        }
      }

      it 'creates a partial court case' do
        expect(create_court_case).to receive(:execute).with(
          hash_including(
            court_date: criteria_attributes[:courtdate]
          )
        )
        subject
      end
    end

    context 'when provided a criteria with a court outcome but without a court date' do
      let(:criteria_attributes) {
        {
          court_outcome: Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_FOR_DIRECTIONS_HEARING,
          courtdate: nil
        }
      }

      it 'creates a partial court case' do
        expect(create_court_case).to receive(:execute).with(
          hash_including(
            court_outcome: criteria_attributes[:court_outcome]
          )
        )
        subject
      end
    end

    context 'when provided a criteria with a court date and a court outcome' do
      let(:criteria_attributes) {
        {
          court_outcome: Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_FOR_DIRECTIONS_HEARING,
          courtdate: DateTime.now.midnight - 7.days
        }
      }

      it 'creates a partial court case' do
        expect(create_court_case).to receive(:execute).with(
          hash_including(
            court_date: criteria_attributes[:courtdate],
            court_outcome: criteria_attributes[:court_outcome]
          )
        )
        subject
      end
    end
  end
end
