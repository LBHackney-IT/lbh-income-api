module Hackney
  module Income
    module TenancyClassification
      module V2
        module Rulesets
          class SendCourtAgreementBreachLetter < BaseRuleset
            def execute
              return :send_court_agreement_breach_letter if action_valid
            end

            private

            def action_valid
              return false if should_prevent_action?
              return false if @criteria.last_communication_action.in?(valid_actions_to_send_court_agreement_breach_letter)

              court_breach_agreement?
            end

            def valid_actions_to_send_court_agreement_breach_letter
              [
                Hackney::Tenancy::ActionCodes::COURT_BREACH_LETTER_SENT,
                Hackney::Tenancy::ActionCodes::VISIT_MADE
              ]
            end
          end
        end
      end
    end
  end
end
