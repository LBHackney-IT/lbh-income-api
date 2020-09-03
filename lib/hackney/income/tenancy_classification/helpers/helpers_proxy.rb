module Hackney
  module Income
    module TenancyClassification
      module Helpers
        module HelpersProxy
          # The intention of this class if to be able to run the existing classification engine
          # with both Manage Arrears data and Universal Housing data.
          include Hackney::Income::TenancyClassification::Helpers::MAAgreementHelpers
          include Hackney::Income::TenancyClassification::Helpers::MACourtCaseHelpers
          include Hackney::Income::TenancyClassification::Helpers::UHAgreementHelpers
          include Hackney::Income::TenancyClassification::Helpers::UHCourtCaseHelpers

          def active_agreement?
            if @use_ma_data
              active_agreement_ma?
            else
              active_agreement_uh?
            end
          end

          def informal_breached_agreement?
            if @use_ma_data
              informal_breached_agreement_ma?
            else
              informal_breached_agreement_uh?
            end
          end

          def breached_agreement?
            if @use_ma_data
              breached_agreement_ma?
            else
              breached_agreement_uh?
            end
          end

          def court_breach_agreement?
            if @use_ma_data
              court_breach_agreement_ma?
            else
              court_breach_agreement_uh?
            end
          end

          def court_warrant_active?
            if @use_ma_data
              court_warrant_active_ma?
            else
              court_warrant_active_uh?
            end
          end

          def court_date_in_future?
            if @use_ma_data
              court_date_in_future_ma?
            else
              court_date_in_future_uh?
            end
          end

          def no_court_date?
            if @use_ma_data
              no_court_date_ma?
            else
              no_court_date_uh?
            end
          end

          def court_outcome_missing?
            if @use_ma_data
              court_outcome_missing_ma?
            else
              court_outcome_missing_uh?
            end
          end

          def court_date
            if @use_ma_data
              court_date_ma
            else
              court_date_uh
            end
          end

          def court_outcome
            if @use_ma_data
              court_outcome_ma
            else
              court_outcome_uh
            end
          end
        end
      end
    end
  end
end
