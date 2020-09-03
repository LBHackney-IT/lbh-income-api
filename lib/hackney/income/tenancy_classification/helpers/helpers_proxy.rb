module Hackney
  module Income
    module TenancyClassification
      module Helpers
        module HelpersProxy
          # The intention of this class if to be able to run the existing classification engine
          # with both Manage Arrears data and Universal Housing data.
          include Hackney::Income::TenancyClassification::Helpers::AgreementHelpers
          include Hackney::Income::TenancyClassification::Helpers::CourtCaseHelpers

          def active_agreement?
            active_agreement_ma?
          end

          def informal_breached_agreement?
            informal_breached_agreement_ma?
          end

          def breached_agreement?
            breached_agreement_ma?
          end

          def court_breach_agreement?
            court_breach_agreement_ma?
          end

          def court_warrant_active?
            court_warrant_active_ma?
          end

          def court_date_in_future?
            court_date_in_future_ma?
          end

          def no_court_date?
            no_court_date_ma?
          end

          def court_outcome_missing?
            court_outcome_missing_ma?
          end

          def court_date
            court_date_ma
          end

          def court_outcome
            court_outcome_ma
          end
        end
      end
    end
  end
end
