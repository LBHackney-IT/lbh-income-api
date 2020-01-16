module Hackney
  module Income
    class TenancyPrioritiser
      class TenancyClassification
        def initialize(case_priority, criteria, documents)
          @criteria = criteria
          @case_priority = case_priority
          @documents = documents
        end

        def execute
          wanted_action = nil

          wanted_action ||= :review_failed_letter if review_failed_letter?

          wanted_action ||= :no_action if @criteria.eviction_date.present?
          wanted_action ||= :no_action if @criteria.courtdate&.future?
          wanted_action ||= :no_action if @case_priority.paused?

          wanted_action ||= :apply_for_outright_possession_warrant if apply_for_outright_possession_warrant?

          wanted_action ||= :court_breach_visit if court_breach_visit?
          wanted_action ||= :court_breach_no_payment if court_breach_no_payment?

          wanted_action ||= :send_court_agreement_breach_letter if court_agreement_letter_action?

          wanted_action ||= :send_court_warning_letter if send_court_warning_letter?
          wanted_action ||= :apply_for_court_date if apply_for_court_date?
          wanted_action ||= :update_court_outcome_action if update_court_outcome_action?

          wanted_action ||= :send_NOSP if send_nosp?

          wanted_action ||= :send_letter_two if send_letter_two?
          wanted_action ||= :send_letter_one if send_letter_one?
          wanted_action ||= :send_first_SMS if send_sms?

          wanted_action ||= :no_action

          validate_wanted_action(wanted_action)

          wanted_action
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

          @criteria.court_outcome.in?(outright_possession_court_outcome_codes)
        end

        def review_failed_letter?
          return false if @documents.empty?
          @documents.most_recent.failed? && @documents.most_recent.income_collection?
        end

        def court_breach_visit?
          return false if @criteria.courtdate.blank?
          return false unless court_breach_agreement?

          @criteria.last_communication_action.in?(court_breach_letter_actions) &&
            last_communication_older_than?(7.days.ago) &&
            last_communication_newer_than?(3.months.ago)
        end

        def court_breach_no_payment?
          return false if @criteria.courtdate.blank?
          return false unless court_breach_agreement?
          return false if @criteria.days_since_last_payment.to_i < 8

          @criteria.last_communication_action.in?(valid_actions_for_court_breach_no_payment) &&
            last_communication_older_than?(1.week.ago)
        end

        def update_court_outcome_action?
          return false if @criteria.courtdate.blank?
          return false if @criteria.courtdate.future?

          @criteria.court_outcome.blank?
        end

        def court_agreement_letter_action?
          return false if @criteria.last_communication_action.in?([
            Hackney::Tenancy::ActionCodes::COURT_BREACH_LETTER_SENT,
            Hackney::Tenancy::ActionCodes::VISIT_MADE
          ])

          court_breach_agreement?
        end

        def breached_agreement?
          return false if @criteria.most_recent_agreement.blank?
          return false if @criteria.most_recent_agreement[:start_date].blank?

          @criteria.most_recent_agreement[:breached]
        end

        def court_breach_agreement?
          return false unless breached_agreement?
          return false if @criteria.courtdate.blank?

          @criteria.most_recent_agreement[:start_date] > @criteria.courtdate
        end

        def send_sms?
          return false if @criteria.balance.blank?
          return false if @criteria.last_communication_action.present?
          return false if @criteria.nosp_served?
          return false if @criteria.active_agreement?

          @criteria.balance >= 5
        end

        def send_letter_one?
          return false if @criteria.balance.blank?
          return false if @criteria.weekly_gross_rent.blank?

          return false if @criteria.nosp_served?
          return false if @criteria.active_agreement?

          return false if @criteria.last_communication_action.in?(after_letter_one_actions) &&
                          last_communication_newer_than?(3.months.ago)

          balance_is_in_arrears_by_number_of_weeks?(1)
        end

        def send_letter_two?
          return false if @criteria.balance.blank?
          return false if @criteria.weekly_gross_rent.blank?

          return false if @criteria.active_agreement?
          return false if @criteria.nosp_served?

          return false unless @criteria.last_communication_action.in?(valid_actions_for_letter_two_to_progress)

          return false if last_communication_newer_than?(1.week.ago)
          return false if last_communication_older_than?(3.months.ago)

          balance_is_in_arrears_by_number_of_weeks?(3)
        end

        def send_nosp?
          return false if @criteria.balance.blank?
          return false if @criteria.weekly_gross_rent.blank?

          return false if @criteria.active_agreement?
          return false if @criteria.nosp_served?

          if @criteria.nosp_expiry_date.present?
            return false if @criteria.nosp_expiry_date >= Time.zone.now
          else
            return false unless @criteria.last_communication_action.in?(valid_actions_for_nosp_to_progress)
            return false if last_communication_older_than?(3.months.ago)
            return false if last_communication_newer_than?(1.week.ago)
          end

          balance_is_in_arrears_by_number_of_weeks?(4)
        end

        def send_court_warning_letter?
          return false if @criteria.balance.blank?
          return false if @criteria.weekly_gross_rent.blank?

          return false if @criteria.active_agreement?

          return false if @criteria.last_communication_action.in?(after_court_warning_letter_actions)

          return false unless @criteria.nosp_served?
          return false if @criteria.nosp_served_date.blank?
          return false if @criteria.nosp_served_date > 28.days.ago.to_date
          balance_is_in_arrears_by_number_of_weeks?(4)
        end

        def apply_for_court_date?
          return false if @criteria.balance.blank?
          return false if @criteria.weekly_gross_rent.blank?

          return false unless @criteria.nosp_served?

          return false unless @criteria.last_communication_action.in?(valid_actions_for_apply_for_court_date_to_progress)
          return false if last_communication_newer_than?(2.weeks.ago)

          return false if @criteria.nosp_served_date > 28.days.ago.to_date

          return false if @criteria.courtdate.present? && @criteria.courtdate > @criteria.last_communication_date

          balance_is_in_arrears_by_number_of_weeks?(4)
        end

        def last_communication_older_than?(date)
          @criteria.last_communication_date <= date.to_date
        end

        def last_communication_newer_than?(date)
          @criteria.last_communication_date >= date.to_date
        end

        def balance_is_in_arrears_by_number_of_weeks?(weeks)
          @criteria.balance > arrear_accumulation_by_number_weeks(weeks)
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
      end
    end
  end
end
