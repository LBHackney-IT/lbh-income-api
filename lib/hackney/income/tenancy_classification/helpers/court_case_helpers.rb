module Hackney
  module Income
    module TenancyClassification
      module Helpers
        module CourtCaseHelpers
          include HelpersBase

          def court_warrant_active?
            return false if most_recent_court_case.blank?
            return false if most_recent_court_case.court_date.blank?
            return false if most_recent_court_case.court_outcome.blank?

            if most_recent_court_case.court_outcome.in?([
              Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_GENERALLY_WITH_PERMISSION_TO_RESTORE,
              Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_TO_NEXT_OPEN_DATE,
              Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_TO_ANOTHER_HEARING_DATE,
              Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_FOR_DIRECTIONS_HEARING,
              Hackney::Tenancy::UpdatedCourtOutcomeCodes::SUSPENSION_ON_TERMS,
              Hackney::Tenancy::UpdatedCourtOutcomeCodes::STAY_OF_EXECUTION
            ])
              return most_recent_court_case.court_date > 6.years.ago
            end

            false
          end

          def court_date_in_future?
            return false unless most_recent_court_case.present? && most_recent_court_case.court_date.present?
            most_recent_court_case.court_date.future?
          end

          def no_court_date?
            most_recent_court_case.blank? || most_recent_court_case.court_date.blank?
          end

          def court_outcome_missing?
            return false if court_date_in_future?
            return false if no_court_date?

            most_recent_court_case.court_outcome.blank?
          end

          def court_date
            most_recent_court_case&.court_date
          end

          def court_outcome
            most_recent_court_case&.court_outcome
          end
        end
      end
    end
  end
end
