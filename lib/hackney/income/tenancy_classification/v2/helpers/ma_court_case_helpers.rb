module Hackney
  module Income
    module TenancyClassification
      module V2
        module Helpers
          module MACourtCaseHelpers
            include HelpersBase

            def court_warrant_active?
              return false if most_recent_court_case.blank?
              return false if most_recent_court_case.court_outcome.blank?

              if most_recent_court_case.court_outcome.in?([
                Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY,
                Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_ON_TERMS,
                Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_ON_TERMS_SECONDARY,
                Hackney::Tenancy::CourtOutcomeCodes::SUSPENDED_POSSESSION,
                Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_FORTHWITH,
                Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_WITH_DATE
              ])
                return most_recent_court_case.court_date.blank? || most_recent_court_case.court_date > 6.years.ago
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
          end
        end
      end
    end
  end
end
