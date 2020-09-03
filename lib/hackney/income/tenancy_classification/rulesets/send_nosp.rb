module Hackney
  module Income
    module TenancyClassification
      module Rulesets
        class SendNOSP < BaseRuleset
          def execute
            return :send_NOSP if action_valid
          end

          private

          def action_valid
            return false if should_prevent_action?
            return false if @criteria.collectable_arrears.blank?
            return false if @criteria.weekly_gross_rent.blank?

            return false if active_agreement?

            return false if @criteria.nosp.valid?
            return false if court_warrant_active?

            return false if court_outcome_missing?

            unless @criteria.nosp.served?
              return false unless @criteria.last_communication_action.in?(valid_actions_for_nosp_to_progress)
              return false if last_communication_older_than?(3.months.ago)
              return false if last_communication_newer_than?(1.week.ago)
            end

            balance_is_in_arrears_by_number_of_weeks?(4)
          end

          def valid_actions_for_nosp_to_progress
            [
              Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
              Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH,
              Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH_ALT,
              Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH_ALT_2,
              Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH_ALT_3
            ]
          end
        end
      end
    end
  end
end
