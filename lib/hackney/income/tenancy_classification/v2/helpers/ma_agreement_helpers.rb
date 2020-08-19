module Hackney
  module Income
    module TenancyClassification
      module V2
        module Helpers
          module MAAgreementHelpers
            include HelpersBase

            def active_agreement_ma?
              most_recent_agreement.present? && most_recent_agreement.active?
            end

            def informal_breached_agreement_ma?
              breached_agreement? && !court_breach_agreement?
            end

            def breached_agreement_ma?
              return false if most_recent_agreement.blank?
              return false if most_recent_agreement.start_date.blank?

              most_recent_agreement.breached?
            end

            def court_breach_agreement_ma?
              return false unless breached_agreement?
              return false unless most_recent_agreement.formal?

              most_recent_agreement.start_date > most_recent_court_case.court_date
            end
          end
        end
      end
    end
  end
end
