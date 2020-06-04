module Hackney
  module Income
    module TenancyClassification
      module V2
        module Rulesets
          class ApplyForOutrightPossessionWarrant < BaseRuleset
            def execute
              return :apply_for_outright_possession_warrant if action_valid
            end

            private

            def action_valid
              return false if should_prevent_action?
              return false if @criteria.active_agreement?
              return false if @criteria.courtdate.blank?
              return false if @criteria.courtdate.future?
              return false if @criteria.courtdate < 3.months.ago
              return false if @criteria.last_communication_action.in?(blocking_communication_actions)

              @criteria.court_outcome.in?(prerequisite_court_outcomes_for_action)
            end

            def prerequisite_court_outcomes_for_action
              [
                Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_WITH_DATE,
                Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_FORTHWITH
              ]
            end

            def blocking_communication_actions
              [
                Hackney::Tenancy::ActionCodes::WARRANT_OF_POSSESSION
              ]
            end
          end
        end
      end
    end
  end
end
