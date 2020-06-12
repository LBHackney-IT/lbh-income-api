module Hackney
  module Income
    module TenancyClassification
      module V2
        module Rulesets
          class SendCourtWarningLetter < BaseRuleset
            def execute
              return :send_court_warning_letter if action_valid
            end

            private

            def action_valid
              return false if should_prevent_action?
              return false if @criteria.balance.blank?
              return false if @criteria.weekly_gross_rent.blank?

              return false if @criteria.active_agreement?

              return false if @criteria.last_communication_action.in?(after_court_warning_letter_actions)

              return false unless @criteria.nosp.valid?
              return false unless @criteria.nosp.active?

              balance_is_in_arrears_by_number_of_weeks?(4)
            end

            def after_court_warning_letter_actions
              [
                Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT
              ]
            end
          end
        end
      end
    end
  end
end
