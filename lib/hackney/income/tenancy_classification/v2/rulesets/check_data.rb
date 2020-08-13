module Hackney
  module Income
    module TenancyClassification
      module V2
        module Rulesets
          class CheckData < BaseRuleset
            def execute
              return :check_data if action_valid
            end

            private

            def action_valid
              # Cases should be paused if they have been to court but have no agreement
              return true if !case_paused? && court_warrant_active? && !active_agreement?

              # Cases with court outcomes must have court dates recorded
              return true if !case_paused? && no_court_date? && court_outcome.present?

              false
            end
          end
        end
      end
    end
  end
end
