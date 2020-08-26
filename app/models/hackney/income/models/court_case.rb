module Hackney
  module Income
    module Models
      class CourtCase < ApplicationRecord
        validates_presence_of :tenancy_ref
        validates_inclusion_of :terms, in: [true, false], if: :can_have_terms?
        validates_inclusion_of :disrepair_counter_claim, in: [true, false], if: :can_have_terms?
        validate :court_outcome_is_valid
        has_many :agreements, -> { where agreement_type: :formal }, class_name: 'Hackney::Income::Models::Agreement'

        COURT_OUTCOMES_THAT_CAN_HAVE_TERMS=
          [
            Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_GENERALLY_WITH_PERMISSION_TO_RESTORE,
            Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_TO_NEXT_OPEN_DATE,
            Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_TO_ANOTHER_HEARING_DATE,
            Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_FOR_DIRECTIONS_HEARING,
            Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_ON_TERMS,
            Hackney::Tenancy::UpdatedCourtOutcomeCodes::SUSPENSION_ON_TERMS,
            Hackney::Tenancy::UpdatedCourtOutcomeCodes::STAY_OF_EXECUTION

          ].freeze

        OTHER_COURT_OUTCOMES =
          [
            Hackney::Tenancy::UpdatedCourtOutcomeCodes::STRUCK_OUT,
            Hackney::Tenancy::UpdatedCourtOutcomeCodes::WITHDRAWN_ON_THE_DAY,
            Hackney::Tenancy::UpdatedCourtOutcomeCodes::OUTRIGHT_POSSESSION_FORTHWITH,
            Hackney::Tenancy::UpdatedCourtOutcomeCodes::OUTRIGHT_POSSESSION_WITH_DATE
          ].freeze

        def can_have_terms?
          COURT_OUTCOMES_THAT_CAN_HAVE_TERMS.include?(court_outcome)
        end

        private

        def court_outcome_is_valid
          return unless court_outcome.present?
          errors.add(:court_outcome, 'must be a valid court outcome code') unless (COURT_OUTCOMES_THAT_CAN_HAVE_TERMS + OTHER_COURT_OUTCOMES).include?(court_outcome)
        end
      end
    end
  end
end
