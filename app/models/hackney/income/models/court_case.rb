module Hackney
  module Income
    module Models
      class CourtCase < ApplicationRecord
        after_create :update_associated_worktray_item
        after_update :update_associated_worktray_item

        validates_presence_of :tenancy_ref
        validates_inclusion_of :terms, in: [true, false], if: :can_have_terms?
        validates_inclusion_of :disrepair_counter_claim, in: [true, false], if: :can_have_terms?
        validate :court_outcome_is_valid
        has_many :agreements, -> { where agreement_type: :formal }, class_name: 'Hackney::Income::Models::Agreement'

        COURT_OUTCOMES_THAT_CAN_HAVE_TERMS =
          [
            Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY_WITH_PERMISSION_TO_RESTORE,
            Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_TO_NEXT_OPEN_DATE,
            Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_TO_ANOTHER_HEARING_DATE,
            Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_FOR_DIRECTIONS_HEARING,
            Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_ON_TERMS,
            Hackney::Tenancy::CourtOutcomeCodes::SUSPENSION_ON_TERMS,
            Hackney::Tenancy::CourtOutcomeCodes::STAY_OF_EXECUTION
          ].freeze

        OTHER_COURT_OUTCOMES =
          [
            Hackney::Tenancy::CourtOutcomeCodes::STRUCK_OUT,
            Hackney::Tenancy::CourtOutcomeCodes::WITHDRAWN_ON_THE_DAY,
            Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_FORTHWITH,
            Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_WITH_DATE
          ].freeze

        def can_have_terms?
          COURT_OUTCOMES_THAT_CAN_HAVE_TERMS.include?(court_outcome)
        end

        def result_in_agreement?
          terms.present? && !expired?
        end

        def expired?
          return true if struck_out?
          return true if end_of_life?

          false
        end

        def struck_out?
          strike_out_date.present? && strike_out_date.to_date <= Date.today
        end

        def end_of_life?
          return false if court_date.nil?

          court_outcome == Hackney::Tenancy::CourtOutcomeCodes::SUSPENSION_ON_TERMS && court_date.to_date + 6.years <= Date.today
        end

        private

        def court_outcome_is_valid
          return unless court_outcome.present?

          valid_court_outcomes = COURT_OUTCOMES_THAT_CAN_HAVE_TERMS + OTHER_COURT_OUTCOMES
          errors.add(:court_outcome, 'must be a valid court outcome code') unless valid_court_outcomes.include?(court_outcome)
        end

        def update_associated_worktray_item
          Hackney::Income::Models::CasePriority.find_by(tenancy_ref: tenancy_ref)&.update!(court_outcome: court_outcome, courtdate: court_date)
        end
      end
    end
  end
end
