module Hackney
  module Income
    module TenancyClassification
      module Rulesets
        class SendLetterTwo < BaseRuleset
          def execute
            return :send_letter_two if action_valid
          end

          private

          def action_valid
            return false if should_prevent_action?
            return false if @criteria.collectable_arrears.blank?
            return false if @criteria.weekly_gross_rent.blank?

            return false if active_agreement?
            return false if breached_agreement? && !court_breach_agreement?
            return false if @criteria.nosp.served?

            return false unless @criteria.last_communication_action.in?(valid_actions_for_letter_two_to_progress)

            return false if last_communication_newer_than?(14.days.ago)
            return false if last_communication_older_than?(3.months.ago)

            balance_is_in_arrears_by_amount?(10) && no_court_date?
          end

          def valid_actions_for_letter_two_to_progress
            [
              Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1,
              Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1_UH
            ]
          end
        end
      end
    end
  end
end
