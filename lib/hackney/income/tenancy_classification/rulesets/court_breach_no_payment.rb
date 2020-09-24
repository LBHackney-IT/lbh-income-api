module Hackney
  module Income
    module TenancyClassification
      module Rulesets
        class CourtBreachNoPayment < BaseRuleset
          def execute
            return :court_breach_no_payment if action_valid
          end

          private

          def action_valid
            return false if should_prevent_action?
            return false if court_date.blank?
            return false unless court_breach_agreement?
            return false if @criteria.days_since_last_payment.to_i < 8

            @criteria.last_communication_action.in?(valid_actions_for_court_breach_no_payment) &&
              last_communication_older_than?(1.week.ago)
          end

          def valid_actions_for_court_breach_no_payment
            [
              Hackney::Tenancy::ActionCodes::COURT_BREACH_VISIT_MADE
            ]
          end
        end
      end
    end
  end
end
