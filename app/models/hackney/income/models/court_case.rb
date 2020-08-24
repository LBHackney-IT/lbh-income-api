module Hackney
  module Income
    module Models
      class CourtCase < ApplicationRecord
        validates_presence_of :tenancy_ref
        validates_presence_of :terms, if: :adjourned?
        validates_presence_of :disrepair_counter_claim, if: :adjourned?
        validate :court_outcome_is_valid
        has_many :agreements, -> { where agreement_type: :formal }, class_name: 'Hackney::Income::Models::Agreement'

        ADJOURNED_COURT_OUTCOMES =
          [
            Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_GENERALLY_WITH_PERMISSION_TO_RESTORE,
            Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_TO_NEXT_OPEN_DATE,
            Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_TO_ANOTHER_HEARING_DATE,
            Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_FOR_DIRECTIONS_HEARING
          ].freeze

        OTHER_COURT_OUTCOMES =
          [
            Hackney::Tenancy::UpdatedCourtOutcomeCodes::SUSPENSION_ON_TERMS,
            Hackney::Tenancy::UpdatedCourtOutcomeCodes::STRUCK_OUT,
            Hackney::Tenancy::UpdatedCourtOutcomeCodes::WITHDRAWN_ON_THE_DAY,
            Hackney::Tenancy::UpdatedCourtOutcomeCodes::STAY_OF_EXECUTION
          ].freeze

        def adjourned?
          ADJOURNED_COURT_OUTCOMES.include?(court_outcome)
        end

        private

        def court_outcome_is_valid
          return unless court_outcome.present?
          errors.add(:court_outcome, 'must be a valid court outcome code') unless (ADJOURNED_COURT_OUTCOMES + OTHER_COURT_OUTCOMES).include?(court_outcome)
        end
      end
    end
  end
end
