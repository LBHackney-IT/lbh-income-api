module Hackney
  module Income
    module TenancyClassification
      module Helpers
        module UHCourtCaseHelpers
          def court_warrant_active_uh?
            return false if @criteria.courtdate.blank?
            return false if @criteria.court_outcome.blank?

            if @criteria.court_outcome.in?([
              Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY,
              Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_ON_TERMS,
              Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_ON_TERMS_SECONDARY,
              Hackney::Tenancy::CourtOutcomeCodes::SUSPENDED_POSSESSION,
              Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_FORTHWITH,
              Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_WITH_DATE
            ])
              return @criteria.courtdate > 6.years.ago
            end

            false
          end

          def court_date_in_future_uh?
            @criteria.courtdate.present? && @criteria.courtdate.future?
          end

          def no_court_date_uh?
            @criteria.courtdate.blank?
          end

          def court_outcome_missing_uh?
            return false if court_date_in_future_uh?
            return false if no_court_date_uh?

            @criteria.court_outcome.blank?
          end

          def court_date_uh
            @criteria.courtdate
          end

          def court_outcome_uh
            @criteria.court_outcome
          end
        end
      end
    end
  end
end
