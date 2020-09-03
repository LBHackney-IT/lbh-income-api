module Hackney
  module Income
    module TenancyClassification
      module Rulesets
        class SendInformalAgreementBreachLetter < BaseRuleset
          def execute
            return :send_informal_agreement_breach_letter if action_valid
          end

          private

          def action_valid
            return false if should_prevent_action?
            return false if @criteria.nosp.served? && @criteria.nosp.valid?
            return false if @criteria.last_communication_action.in?([
              Hackney::Tenancy::ActionCodes::INFORMAL_BREACH_LETTER_SENT,
              Hackney::Tenancy::ActionCodes::COURT_BREACH_LETTER_SENT,
              Hackney::Tenancy::ActionCodes::VISIT_MADE
            ])

            if @criteria.last_communication_date.present?
              return false if last_communication_newer_than?(7.days.ago)
            end

            informal_breached_agreement?
          end
        end
      end
    end
  end
end
