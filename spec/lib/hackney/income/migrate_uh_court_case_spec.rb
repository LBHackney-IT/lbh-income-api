require 'rails_helper'

describe Hackney::Income::MigrateUhCourtCase do
  subject(:migrator) {
    described_class.new(
      create_court_case: create_court_case,
      view_court_cases: view_court_cases,
      update_court_case: update_court_case
    ).migrate(criteria)
  }

  let(:create_court_case) { double(Hackney::Income::CreateCourtCase) }
  let(:view_court_cases) { double(Hackney::Income::ViewCourtCases) }
  let(:update_court_case) { double(Hackney::Income::UpdateCourtCase) }

  before do
    allow(view_court_cases).to receive(:execute).and_return(existing_court_cases)
    allow(update_court_case).to receive(:execute).and_return([])
  end

  let(:criteria) { Stubs::StubCriteria.new(criteria_attributes) }
  let(:existing_court_cases) { [] }

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
            tenancy_ref: criteria.tenancy_ref,
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
            tenancy_ref: criteria.tenancy_ref,
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
            tenancy_ref: criteria.tenancy_ref,
            court_date: criteria_attributes[:courtdate],
            court_outcome: criteria_attributes[:court_outcome]
          )
        )
        subject
      end
    end
  end

  context 'when there are multiple court cases in MA' do
    let(:existing_court_cases) {
      [create(:court_case,
              court_date: DateTime.now.midnight - 1.month,
              court_outcome: Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY),
       create(:court_case,
              court_date: DateTime.now.midnight - 7.days,
              court_outcome: nil)]
    }

    context 'when provided with any criteria' do
      let(:criteria_attributes) {
        {
          court_outcome: Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY,
          courtdate: DateTime.now.midnight
        }
      }

      it 'does not update any existing court cases' do
        expect(create_court_case).not_to receive(:execute)
        expect(update_court_case).not_to receive(:execute)
        subject
      end
    end
  end

  context 'when there is a single complete court case in MA' do
    let(:existing_court_cases) {
      [create(:court_case,
              court_date: DateTime.now.midnight - 14.days,
              court_outcome: Hackney::Tenancy::UpdatedCourtOutcomeCodes::SUSPENSION_ON_TERMS)]
    }

    context 'when provided with a criteria' do
      let(:criteria_attributes) {
        {
          court_outcome: Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_FOR_DIRECTIONS_HEARING,
          courtdate: DateTime.now.midnight - 7.days
        }
      }

      it 'does not update the complete court case' do
        expect(create_court_case).not_to receive(:execute)
        expect(update_court_case).not_to receive(:execute)
        subject
      end
    end
  end

  context 'when there is a single partial court case in MA' do
    context 'when a partial court case already exists with a court date but no outcome' do
      let(:existing_court_cases) {
        [create(:court_case,
                court_date: DateTime.now.midnight - 7.days,
                court_outcome: nil)]
      }

      context 'when provided a criteria without a court date or outcome' do
        let(:criteria_attributes) {
          {
            court_outcome: nil,
            courtdate: nil
          }
        }

        it 'does not update the court case' do
          expect(create_court_case).not_to receive(:execute)
          expect(update_court_case).not_to receive(:execute)
          subject
        end
      end

      context 'when provided a criteria with a court date but no outcome' do
        let(:criteria_attributes) {
          {
            court_outcome: nil,
            courtdate: DateTime.now.midnight
          }
        }

        it 'does not update the court case' do
          expect(create_court_case).not_to receive(:execute)
          expect(update_court_case).not_to receive(:execute)
          subject
        end
      end

      context 'when provided a criteria with a court date and an outcome' do
        let(:criteria_attributes) {
          {
            court_outcome: Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY,
            courtdate: DateTime.now.midnight
          }
        }

        it 'does update the court case with the court outcome only' do
          expect(create_court_case).not_to receive(:execute)
          expect(update_court_case).to receive(:execute).with(
            id: existing_court_cases[0].id,
            court_date: nil,
            court_outcome: criteria_attributes[:court_outcome]
          )
          subject
        end
      end
    end

    context 'when a partial court case already exists without a court date but has an outcome' do
      let(:existing_court_cases) {
        [create(:court_case,
                court_date: nil,
                court_outcome: Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY)]
      }

      context 'when provided a criteria without a court date or outcome' do
        let(:criteria_attributes) {
          {
            court_outcome: nil,
            courtdate: nil
          }
        }

        it 'does not update the court case' do
          expect(create_court_case).not_to receive(:execute)
          expect(update_court_case).not_to receive(:execute)
          subject
        end
      end

      context 'when provided a criteria with a court date but no outcome' do
        let(:criteria_attributes) {
          {
            court_outcome: nil,
            courtdate: DateTime.now.midnight
          }
        }

        it 'does update the court case with the date' do
          expect(create_court_case).not_to receive(:execute)
          expect(update_court_case).to receive(:execute).with(
            id: existing_court_cases[0].id,
            court_date: criteria_attributes[:courtdate],
            court_outcome: nil
          )
          subject
        end
      end

      context 'when provided a criteria with a court date and an outcome' do
        let(:criteria_attributes) {
          {
            court_outcome: Hackney::Tenancy::CourtOutcomeCodes::SUSPENDED_POSSESSION,
            courtdate: DateTime.now.midnight
          }
        }

        it 'does update the court case with the court date only' do
          expect(update_court_case).to receive(:execute).with(
            id: existing_court_cases[0].id,
            court_date: criteria_attributes[:courtdate],
            court_outcome: nil
          )
          subject
        end
      end

      context 'when provided a criteria with only an outcome' do
        let(:criteria_attributes) {
          {
            court_outcome: Hackney::Tenancy::CourtOutcomeCodes::SUSPENDED_POSSESSION,
            courtdate: nil
          }
        }

        it 'does not update the court case' do
          expect(update_court_case).not_to receive(:execute)
          subject
        end
      end
    end
  end
end
