module Hackney
  module Income
    module TenancyClassification
      module V2
        class Classifier
          def initialize(case_priority, criteria, documents)
            @criteria = criteria
            @case_priority = case_priority
            @documents = documents
          end

          def execute
            actions = []

            actions << Rulesets::ReviewFailedLetter.execute(@case_priority, @criteria, @documents)

            actions << :apply_for_outright_possession_warrant if apply_for_outright_possession_warrant?

            actions << :court_breach_visit if court_breach_visit?
            actions << :court_breach_no_payment if court_breach_no_payment?

            # TODO(AO): Possible missing test for below
            actions << :send_court_agreement_breach_letter if court_agreement_letter_action?

            actions << :send_court_warning_letter if send_court_warning_letter?
            actions << :apply_for_court_date if apply_for_court_date?
            actions << :update_court_outcome_action if update_court_outcome_action?

            actions << :send_informal_agreement_breach_letter if informal_agreement_breach_letter?
            actions << :informal_breached_after_letter if informal_breached_after_letter?

            actions << :send_NOSP if send_nosp?

            actions << :send_letter_two if send_letter_two?
            actions << :send_letter_one if send_letter_one?
            actions << :send_first_SMS if send_sms?

            actions.compact!

            actions << :no_action if actions.none?

            if actions.length > 1 && actions != %i[send_letter_one send_first_SMS]
              Rails.logger.error(
                'CLASSIFIER: Multiple recommended actions from V2' \
                "Actions: #{actions} " \
                "Criteria: #{@criteria} " \
                "CasePriority: #{@case_priority} " \
                "Document Count: #{@documents.length}"
              )
            end

            validate_wanted_action(actions.first)

            actions.first
          end

          private

          def validate_wanted_action(wanted_action)
            return false if Hackney::Income::Models::CasePriority.classifications.key?(wanted_action)
            raise ArgumentError, "Tried to classify a case as #{wanted_action}, but this is not on the list of valid classifications."
          end

          def apply_for_outright_possession_warrant?
            return false if @criteria.active_agreement?
            return false if @criteria.courtdate.blank?
            return false if @criteria.courtdate.future?
            return false if @criteria.courtdate < 3.months.ago
            return false if @criteria.last_communication_action.in?(after_apply_for_outright_possession_actions)

            @criteria.court_outcome.in?(outright_possession_court_outcome_codes) && should_prevent_action?
          end

          def court_breach_visit?
            return false if @criteria.courtdate.blank?
            return false unless court_breach_agreement?

            @criteria.last_communication_action.in?(court_breach_letter_actions) &&
              last_communication_older_than?(7.days.ago) &&
              last_communication_newer_than?(3.months.ago) && should_prevent_action?
          end

          def court_breach_no_payment?
            return false if @criteria.courtdate.blank?
            return false unless court_breach_agreement?
            return false if @criteria.days_since_last_payment.to_i < 8

            @criteria.last_communication_action.in?(valid_actions_for_court_breach_no_payment) &&
              last_communication_older_than?(1.week.ago) && should_prevent_action?
          end

          def update_court_outcome_action?
            return false if @criteria.courtdate.blank?
            return false if @criteria.courtdate.future?

            @criteria.court_outcome.blank? && should_prevent_action?
          end

          def court_agreement_letter_action?
            return false if @criteria.last_communication_action.in?([
              Hackney::Tenancy::ActionCodes::COURT_BREACH_LETTER_SENT,
              Hackney::Tenancy::ActionCodes::VISIT_MADE
            ])

            court_breach_agreement? && should_prevent_action?
          end

          def breached_agreement?
            return false if @criteria.most_recent_agreement.blank?
            return false if @criteria.most_recent_agreement[:start_date].blank?

            @criteria.most_recent_agreement[:breached] && should_prevent_action?
          end

          def informal_breached_agreement?
            breached_agreement? && !court_breach_agreement? && should_prevent_action?
          end

          def informal_agreement_breach_letter?
            return false if @criteria.nosp.served?
            return false if @criteria.last_communication_action.in?([
              Hackney::Tenancy::ActionCodes::INFORMAL_BREACH_LETTER_SENT,
              Hackney::Tenancy::ActionCodes::COURT_BREACH_LETTER_SENT,
              Hackney::Tenancy::ActionCodes::VISIT_MADE
            ])

            if @criteria.last_communication_date.present?
              return false if last_communication_newer_than?(7.days.ago)
            end

            informal_breached_agreement? && should_prevent_action?
          end

          def informal_breached_after_letter?
            return false if @criteria.nosp.served?
            return false if @criteria.last_communication_action != Hackney::Tenancy::ActionCodes::INFORMAL_BREACH_LETTER_SENT
            return false if last_communication_newer_than?(7.days.ago)

            informal_breached_agreement? && should_prevent_action?
          end

          def court_breach_agreement?
            return false unless breached_agreement?
            return false if @criteria.courtdate.blank?

            @criteria.most_recent_agreement[:start_date] > @criteria.courtdate && should_prevent_action?
          end

          def send_sms?
            return false if @criteria.balance.blank?
            return false if @criteria.courtdate.present?
            return false if @criteria.nosp.served?
            return false if @criteria.active_agreement?

            if @criteria.last_communication_action.present?
              return false if @criteria.last_communication_action.in?(sms_action_codes) &&
                              last_communication_newer_than?(7.days.ago)

              return false if !@criteria.last_communication_action.in?(sms_action_codes) &&
                              last_communication_newer_than?(3.months.ago)
            end

            @criteria.balance >= 5 && should_prevent_action? && no_court_date?
          end

          def send_letter_one?
            return false if @criteria.balance.blank?
            return false if @criteria.weekly_gross_rent.blank?
            return false if @criteria.nosp.served?
            return false if @criteria.active_agreement?

            return false if @criteria.last_communication_action.in?(after_letter_one_actions) &&
                            last_communication_newer_than?(3.months.ago)

            balance_is_in_arrears_by_amount?(10) && should_prevent_action? && no_court_date?
          end

          def send_letter_two?
            return false if @criteria.balance.blank?
            return false if @criteria.weekly_gross_rent.blank?

            return false if @criteria.active_agreement?
            return false if @criteria.nosp.served?

            return false unless @criteria.last_communication_action.in?(valid_actions_for_letter_two_to_progress)

            return false if last_communication_newer_than?(14.days.ago)
            return false if last_communication_older_than?(3.months.ago)

            balance_is_in_arrears_by_amount?(10) && should_prevent_action? && no_court_date?
          end

          def send_nosp?
            return false if @criteria.balance.blank?
            return false if @criteria.weekly_gross_rent.blank?

            return false if @criteria.active_agreement?

            return false if @criteria.nosp.valid?
            return false if @criteria.court_outcome.blank?

            unless @criteria.nosp.served?
              return false unless @criteria.last_communication_action.in?(valid_actions_for_nosp_to_progress)
              return false if last_communication_older_than?(3.months.ago)
              return false if last_communication_newer_than?(1.week.ago)
            end

            balance_is_in_arrears_by_number_of_weeks?(4) && should_prevent_action?
          end

          def send_court_warning_letter?
            return false if @criteria.balance.blank?
            return false if @criteria.weekly_gross_rent.blank?

            return false if @criteria.active_agreement?

            return false if @criteria.last_communication_action.in?(after_court_warning_letter_actions)

            return false unless @criteria.nosp.valid?
            return false unless @criteria.nosp.active?

            balance_is_in_arrears_by_number_of_weeks?(4) && should_prevent_action?
          end

          def apply_for_court_date?
            return false if @criteria.balance.blank?
            return false if @criteria.weekly_gross_rent.blank?
            return false if @criteria.active_agreement?

            return false unless @criteria.nosp.served?

            return false unless @criteria.last_communication_action.in?(valid_actions_for_apply_for_court_date_to_progress)
            return false if last_communication_newer_than?(2.weeks.ago)

            return false unless @criteria.nosp.active?

            return false if @criteria.courtdate.present? && @criteria.courtdate > @criteria.last_communication_date

            balance_is_in_arrears_by_number_of_weeks?(4) && should_prevent_action?
          end

          def case_has_eviction_date?
            @criteria.eviction_date.present?
          end

          def court_date_in_future?
            @criteria.courtdate&.future?
          end

          def no_court_date?
            @criteria.courtdate.blank?
          end

          def case_paused?
            @case_priority.paused?
          end

          def should_prevent_action?
            !(case_has_eviction_date? || court_date_in_future? || case_paused?)
          end

          def last_communication_older_than?(date)
            @criteria.last_communication_date <= date.to_date
          end

          def last_communication_newer_than?(date)
            @criteria.last_communication_date > date.to_date
          end

          def balance_is_in_arrears_by_number_of_weeks?(weeks)
            balance_with_1_week_grace >= arrear_accumulation_by_number_weeks(weeks)
          end

          def balance_is_in_arrears_by_amount?(amount)
            balance_with_1_week_grace >= amount
          end

          def balance_with_1_week_grace
            @criteria.balance - calculated_grace_amount
          end

          def calculated_grace_amount
            grace_amount = @criteria.weekly_gross_rent + @criteria.total_payment_amount_in_week

            return 0 if grace_amount.negative?

            grace_amount
          end

          def arrear_accumulation_by_number_weeks(weeks)
            @criteria.weekly_gross_rent * weeks
          end

          def court_breach_letter_actions
            [
              Hackney::Tenancy::ActionCodes::COURT_BREACH_LETTER_SENT
            ]
          end

          def valid_actions_for_court_breach_no_payment
            [
              Hackney::Tenancy::ActionCodes::VISIT_MADE
            ]
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

          def valid_actions_for_letter_two_to_progress
            [
              Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1,
              Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1_UH
            ]
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

          def outright_possession_court_outcome_codes
            [
              Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_WITH_DATE,
              Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_FORTHWITH
            ]
          end

          def after_apply_for_outright_possession_actions
            [
              Hackney::Tenancy::ActionCodes::WARRANT_OF_POSSESSION
            ]
          end

          def sms_action_codes
            [
              Hackney::Tenancy::ActionCodes::AUTOMATED_SMS_ACTION_CODE,
              Hackney::Tenancy::ActionCodes::MANUAL_SMS_ACTION_CODE,
              Hackney::Tenancy::ActionCodes::MANUAL_GREEN_SMS_ACTION_CODE,
              Hackney::Tenancy::ActionCodes::MANUAL_AMBER_SMS_ACTION_CODE,
              Hackney::Tenancy::ActionCodes::TEXT_MESSAGE_SENT
            ]
          end
        end
      end
    end
  end
end
