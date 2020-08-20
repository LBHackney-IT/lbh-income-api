module Hackney
  module Income
    module TenancyClassification
      module V2
        module Rulesets
          class SendLetterOne < BaseRuleset
            def execute
              return :send_letter_one if action_valid
            end

            private

            def action_valid
              return false if should_prevent_action?
              return false if @criteria.collectable_arrears.blank?
              return false if @criteria.weekly_gross_rent.blank?
              return false if @criteria.nosp.served?
              return false if active_agreement?
              return false if breached_agreement? && !court_breach_agreement?

              return false if @criteria.last_communication_action.in?(after_letter_one_actions) &&
                              last_communication_newer_than?(3.months.ago)

              balance_is_in_arrears_by_amount?(10) && no_court_date?
            end

            def after_letter_one_actions
              [
                Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1,
                Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1_UH,
                Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
                Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH,
                Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH_ALT,
                Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH_ALT_2,
                Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH_ALT_3,
                Hackney::Tenancy::ActionCodes::S0A_ALTERNATIVE_LETTER,
                Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT
              ]
            end
          end
        end
      end
    end
  end
end
