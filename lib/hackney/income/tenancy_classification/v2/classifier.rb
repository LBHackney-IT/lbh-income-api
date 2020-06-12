module Hackney
  module Income
    module TenancyClassification
      module V2
        class Classifier
          include Helpers

          def initialize(case_priority, criteria, documents)
            @criteria = criteria
            @case_priority = case_priority
            @documents = documents
          end

          def execute
            rulesets = [
              Rulesets::ApplyForOutrightPossessionWarrant,
              Rulesets::ReviewFailedLetter,
              Rulesets::SendSMS,
              Rulesets::SendLetterOne,
              Rulesets::SendLetterTwo,
              Rulesets::UpdateCourtOutcomeAction,
              Rulesets::CourtBreachVisit,
              Rulesets::SendNOSP,
              Rulesets::CourtBreachNoPayment,
              Rulesets::SendInformalAgreementBreachLetter,
              Rulesets::InformalBreachedAfterLetter,
              Rulesets::SendCourtAgreementBreachLetter, # TODO(AO): Possible missing test for this classification
              Rulesets::SendCourtWarningLetter
            ]

            actions = rulesets.map { |ruleset| ruleset.new(@case_priority, @criteria, @documents).execute }

            actions << :apply_for_court_date if apply_for_court_date?

            actions.compact!

            actions << :no_action if actions.none?

            if actions.length > 1
              if actions == %i[send_first_SMS send_letter_one]
                actions = %i[send_letter_one]
              else
                Rails.logger.error(
                  'CLASSIFIER: Multiple recommended actions from V2' \
                  "Actions: #{actions} " \
                  "Criteria: #{@criteria} " \
                  "CasePriority: #{@case_priority} " \
                  "Document Count: #{@documents.length}"
                )
              end
            end

            validate_wanted_action(actions.first)

            actions.first
          end

          private

          def validate_wanted_action(wanted_action)
            return false if Hackney::Income::Models::CasePriority.classifications.key?(wanted_action)
            raise ArgumentError, "Tried to classify a case as #{wanted_action}, but this is not on the list of valid classifications."
          end

          def apply_for_court_date?
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

          def case_has_eviction_date?
            @criteria.eviction_date.present?
          end

          def court_date_in_future?
            @criteria.courtdate&.future?
          end

          def case_paused?
            @case_priority.paused?
          end

          def valid_actions_for_apply_for_court_date_to_progress
            [
              Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT
            ]
          end

          def active_agreement_court_outcomes
            [
              Hackney::Tenancy::ActionCodes::ADJOURNED_ON_TERMS_COURT_OUTCOME,
              Hackney::Tenancy::ActionCodes::POSTPONED_POSSESSIOON_COURT_OUTCOME,
              Hackney::Tenancy::ActionCodes::SUSPENDED_POSSESSION_COURT_OUTCOME
            ]
          end
        end
      end
    end
  end
end
