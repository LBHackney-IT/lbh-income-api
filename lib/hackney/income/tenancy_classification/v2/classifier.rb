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
              Rulesets::CourtBreachNoPayment
            ]

            actions = rulesets.map { |ruleset| ruleset.new(@case_priority, @criteria, @documents).execute }

            # TODO(AO): Possible missing test for below
            actions << :send_court_agreement_breach_letter if court_agreement_letter_action?

            actions << :send_court_warning_letter if send_court_warning_letter?
            actions << :apply_for_court_date if apply_for_court_date?

            actions << :send_informal_agreement_breach_letter if informal_agreement_breach_letter?
            actions << :informal_breached_after_letter if informal_breached_after_letter?


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

          def court_agreement_letter_action?
            return false if should_prevent_action?
            return false if @criteria.last_communication_action.in?([
              Hackney::Tenancy::ActionCodes::COURT_BREACH_LETTER_SENT,
              Hackney::Tenancy::ActionCodes::VISIT_MADE
            ])

            court_breach_agreement?
          end

          def informal_breached_agreement?
            return false if should_prevent_action?
            breached_agreement? && !court_breach_agreement?
          end

          def informal_agreement_breach_letter?
            return false if should_prevent_action?
            return false if @criteria.nosp.served?
            return false if @criteria.last_communication_action.in?([
              Hackney::Tenancy::ActionCodes::INFORMAL_BREACH_LETTER_SENT,
              Hackney::Tenancy::ActionCodes::COURT_BREACH_LETTER_SENT,
              Hackney::Tenancy::ActionCodes::VISIT_MADE
            ])

            if @criteria.last_communication_date.present?
              return false if last_communication_newer_than?(7.days.ago)
            end

            informal_breached_agreement?
          end

          def informal_breached_after_letter?
            return false if should_prevent_action?
            return false if @criteria.nosp.served?
            return false if @criteria.last_communication_action != Hackney::Tenancy::ActionCodes::INFORMAL_BREACH_LETTER_SENT
            return false if last_communication_newer_than?(7.days.ago)

            informal_breached_agreement?
          end


          def send_court_warning_letter?
            return false if should_prevent_action?
            return false if @criteria.balance.blank?
            return false if @criteria.weekly_gross_rent.blank?

            return false if @criteria.active_agreement?

            return false if @criteria.last_communication_action.in?(after_court_warning_letter_actions)

            return false unless @criteria.nosp.valid?
            return false unless @criteria.nosp.active?

            balance_is_in_arrears_by_number_of_weeks?(4)
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

          def balance_is_in_arrears_by_number_of_weeks?(weeks)
            balance_with_1_week_grace >= arrear_accumulation_by_number_weeks(weeks)
          end

          def arrear_accumulation_by_number_weeks(weeks)
            @criteria.weekly_gross_rent * weeks
          end

          def valid_actions_for_court_breach_no_payment
            [
              Hackney::Tenancy::ActionCodes::VISIT_MADE
            ]
          end

          def after_court_warning_letter_actions
            [
              Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT
            ]
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
