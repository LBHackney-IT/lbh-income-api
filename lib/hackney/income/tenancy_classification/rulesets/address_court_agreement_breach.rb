module Hackney
  module Income
    module TenancyClassification
      module Rulesets
        class AddressCourtAgreementBreach < BaseRuleset
          def execute
            return :address_court_agreement_breach if action_valid
          end

          private

          def action_valid
            return false if should_prevent_action?
            return false if @criteria.last_communication_action.in?(valid_actions_to_address_court_agreement_breach)

            court_breach_agreement?
          end

          def valid_actions_to_address_court_agreement_breach
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
