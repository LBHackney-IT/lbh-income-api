module Hackney
  module Income
    module TenancyClassification
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

            # Cases with court case that should have agreement
            return true if !case_paused? && court_agreement_missing?

            false
          end

          def court_agreement_missing?
            return false unless most_recent_court_case.present? && most_recent_court_case.result_in_agreement?
            return true unless most_recent_agreement.present? && most_recent_agreement.formal?
            most_recent_agreement.start_date < most_recent_court_case.court_date
          end
        end
      end
    end
  end
end
