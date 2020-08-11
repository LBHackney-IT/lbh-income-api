module Hackney
  module Income
    module TenancyClassification
      module V2
        module Helpers
          module MAAgreementHelpers
            def active_agreement?
              most_recent_agreement.present? && most_recent_agreement.active?
            end

            def informal_breached_agreement?
              breached_agreement? && !court_breach_agreement?
            end

            def breached_agreement?
              return false if most_recent_agreement.blank?

              most_recent_agreement.breached?
            end

            def court_breach_agreement?
              return false unless breached_agreement?
              return false unless most_recent_agreement.formal?

              most_recent_agreement.start_date > most_recent_court_case.court_date
            end

            def most_recent_agreement
              @most_recent_agreement ||= Hackney::Income::Models::Agreement.where(tenancy_ref: @criteria.tenancy_ref).last
            end

            def most_recent_court_case
              @most_recent_court_case ||= Hackney::Income::Models::CourtCase.where(tenancy_ref: @criteria.tenancy_ref).last
            end
          end
        end
      end
    end
  end
end
