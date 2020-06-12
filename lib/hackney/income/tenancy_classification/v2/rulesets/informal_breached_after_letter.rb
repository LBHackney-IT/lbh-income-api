module Hackney
  module Income
    module TenancyClassification
      module V2
        module Rulesets
          class InformalBreachedAfterLetter < BaseRuleset
            def execute
              return :informal_breached_after_letter if action_valid
            end

            private

            def action_valid
              return false if should_prevent_action?
              return false if @criteria.nosp.served?
              return false if @criteria.last_communication_action != Hackney::Tenancy::ActionCodes::INFORMAL_BREACH_LETTER_SENT
              return false if last_communication_newer_than?(7.days.ago)

              informal_breached_agreement?
            end
          end
        end
      end
    end
  end
end
