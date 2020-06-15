module Hackney
  module Income
    module TenancyClassification
      module V2
        module Rulesets
          class ApplyForCourtDate < BaseRuleset
            def execute
              return :apply_for_court_date if action_valid
            end

            private

            def action_valid
              return false if should_prevent_action?
              return false if @criteria.balance.blank?
              return false if @criteria.weekly_gross_rent.blank?
              return false if @criteria.active_agreement?

              return false unless @criteria.nosp.served?

              return false unless @criteria.last_communication_action.in?(valid_actions_for_apply_for_court_date_to_progress)
              return false if last_communication_newer_than?(2.weeks.ago)

              return false unless @criteria.nosp.active?

              return false if @criteria.courtdate.present? && @criteria.courtdate > @criteria.last_communication_date

              balance_is_in_arrears_by_number_of_weeks?(4)
            end

            def valid_actions_for_apply_for_court_date_to_progress
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
