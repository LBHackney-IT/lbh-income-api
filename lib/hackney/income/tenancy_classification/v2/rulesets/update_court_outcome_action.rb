module Hackney
  module Income
    module TenancyClassification
      module V2
        module Rulesets
          class UpdateCourtOutcomeAction < BaseRuleset
            def execute
              return :update_court_outcome_action if action_valid
            end

            private

            def action_valid
              return false if should_prevent_action?
              return false if court_date.blank?
              return false if court_date.future?
              return false if court_breach_agreement?

              court_outcome.blank?
            end
          end
        end
      end
    end
  end
end
