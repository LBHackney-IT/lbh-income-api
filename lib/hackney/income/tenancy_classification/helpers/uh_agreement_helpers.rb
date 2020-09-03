module Hackney
  module Income
    module TenancyClassification
      module Helpers
        module UHAgreementHelpers
          def active_agreement_uh?
            @criteria.active_agreement? || (@criteria.most_recent_agreement.present? && @criteria.most_recent_agreement[:status].in?(%i[active breached]))
          end

          def informal_breached_agreement_uh?
            breached_agreement? && !court_breach_agreement?
          end

          def breached_agreement_uh?
            return false if @criteria.most_recent_agreement.blank?
            return false if @criteria.most_recent_agreement[:start_date].blank?

            @criteria.most_recent_agreement[:breached]
          end

          def court_breach_agreement_uh?
            return false unless breached_agreement?
            return false if @criteria.courtdate.blank?

            @criteria.most_recent_agreement[:start_date] > @criteria.courtdate
          end
        end
      end
    end
  end
end
