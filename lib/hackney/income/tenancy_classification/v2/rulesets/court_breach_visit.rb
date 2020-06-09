module Hackney
  module Income
    module TenancyClassification
      module V2
        module Rulesets
          class CourtBreachVisit < BaseRuleset
            def execute
              return :court_breach_visit if action_valid
            end

            private

            def action_valid
              return false if should_prevent_action?
              return false if @criteria.courtdate.blank?
              return false unless court_breach_agreement?

              @criteria.last_communication_action.in?(court_breach_letter_actions) &&
                last_communication_older_than?(7.days.ago) &&
                last_communication_newer_than?(3.months.ago)
            end
          end
        end
      end
    end
  end
end
