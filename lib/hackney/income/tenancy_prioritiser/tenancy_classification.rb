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

          wanted_action ||= :send_court_agreement_breach_letter if send_court_agreement_breach_letter?
          wanted_action ||= :send_informal_agreement_breach_letter if send_informal_agreement_breach_letter?
          wanted_action ||= :court_breach_visit if court_breach_visit?

          wanted_action ||= breach_letter_action

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
          @criteria.court_outcome == Hackney::Tenancy::ActionCodes::OUTRIGHT_POSSESSION_ORDER
        end

        def send_informal_agreement_breach_letter?
          return false if @criteria.balance.blank?
          return false if @criteria.number_of_broken_agreements.zero?
          return false if @criteria.active_agreement? == true
          return false if @criteria.balance >= @criteria.expected_balance
          return false if @criteria.courtdate.present? && @criteria.courtdate < Date.today
          return false if @criteria.breach_agreement_date + 3.days > Date.today
          return false unless @criteria.last_communication_action.in?(valid_actions_for_court_agreement_breach_letter_to_progress)
          true
        end

        def court_breach_visit?
          @criteria.last_communication_action.in?(court_breach_letter_actions) && last_communication_newer_than?(3.months.ago)
        end

        def review_failed_letter?
          return false if @documents.empty?
          @documents.most_recent.failed? && @documents.most_recent.income_collection?
        end

        def update_court_outcome_action?
          return false if @criteria.courtdate.blank?
          return false if @criteria.courtdate.future?

          @criteria.court_outcome.blank?
        end

        def send_court_agreement_breach_letter?
          return false if @criteria.balance.blank?
          return false if @criteria.number_of_broken_agreements < 1
          return false if @criteria.active_agreement? == true
          return false if @criteria.balance >= @criteria.expected_balance
          return false if @criteria.latest_active_agreement_date.blank?
          return false if @criteria.courtdate.blank?
          return false if @criteria.latest_active_agreement_date <= @criteria.courtdate
          return false if @criteria.breach_agreement_date.present? && @criteria.breach_agreement_date + 3.days > Date.today
          return false if @criteria.balance >= @criteria.expected_balance
          return false unless @criteria.court_outcome.in?(active_agreement_court_outcomes)
          return false unless @criteria.last_communication_action.in?(valid_actions_for_court_agreement_breach_letter_to_progress)
          true
        end

        def breach_letter_action
          return if @criteria.most_recent_agreement.blank?
          return if @criteria.most_recent_agreement[:start_date].blank?
          return unless @criteria.most_recent_agreement[:breached]

          return :send_informal_agreement_breach_letter if @criteria.courtdate.blank?

          court_date_after_agreement = @criteria.courtdate > @criteria.most_recent_agreement[:start_date]
          agreement_months_after_court_date = @criteria.courtdate + 3.months < @criteria.most_recent_agreement[:start_date]

          if court_date_after_agreement || agreement_months_after_court_date
            :send_informal_agreement_breach_letter
          else
            :send_court_agreement_breach_letter
          end
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
          return false if @criteria.weekly_rent.blank?

          return false if @criteria.nosp_served?
          return false if @criteria.active_agreement?

          return false if @criteria.last_communication_action.in?(after_letter_one_actions) &&
                          last_communication_newer_than?(3.months.ago)

          @criteria.balance >= arrear_accumulation_by_number_weeks(1)
        end

        def send_letter_two?
          return false if @criteria.balance.blank?
          return false if @criteria.weekly_rent.blank?

          return false if @criteria.active_agreement?
          return false if @criteria.nosp_served?

          return false unless @criteria.last_communication_action.in?(valid_actions_for_letter_two_to_progress)

          return false if last_communication_newer_than?(1.week.ago)
          return false if last_communication_older_than?(3.months.ago)

          @criteria.balance >= arrear_accumulation_by_number_weeks(3)
        end

        def send_nosp?
          return false if @criteria.balance.blank?
          return false if @criteria.weekly_rent.blank?

          return false if @criteria.active_agreement?
          return false if @criteria.nosp_served?

          if @criteria.nosp_expiry_date.present?
            return false if @criteria.nosp_expiry_date >= Time.zone.now
          else
            return false unless @criteria.last_communication_action.in?(valid_actions_for_nosp_to_progress)
            return false if last_communication_older_than?(3.months.ago)
            return false if last_communication_newer_than?(1.week.ago)
          end

          @criteria.balance >= arrear_accumulation_by_number_weeks(4)
        end

        def send_court_warning_letter?
          return false if @criteria.balance.blank?
          return false if @criteria.weekly_rent.blank?

          return false if @criteria.active_agreement?

          return false if @criteria.last_communication_action.in?(after_court_warning_letter_actions)

          return false unless @criteria.nosp_served?
          return false if @criteria.nosp_served_date.blank?
          return false if @criteria.nosp_served_date > 28.days.ago.to_date
          @criteria.balance >= arrear_accumulation_by_number_weeks(4)
        end

        def apply_for_court_date?
          return false if @criteria.balance.blank?
          return false if @criteria.weekly_rent.blank?

          return false unless @criteria.nosp_served?

          return false unless @criteria.last_communication_action.in?(valid_actions_for_apply_for_court_date_to_progress)
          return false if last_communication_newer_than?(2.weeks.ago)

          return false if @criteria.nosp_served_date > 28.days.ago.to_date

          return false if @criteria.courtdate.present? && @criteria.courtdate > @criteria.last_communication_date

          @criteria.balance >= arrear_accumulation_by_number_weeks(4)
        end

        def last_communication_older_than?(date)
          @criteria.last_communication_date <= date.to_date
        end

        def last_communication_newer_than?(date)
          @criteria.last_communication_date >= date.to_date
        end

        def arrear_accumulation_by_number_weeks(weeks)
          @criteria.weekly_rent * weeks
        end

        def court_breach_letter_actions
          [
            Hackney::Tenancy::ActionCodes::COURT_BREACH_LETTER_SENT
          ]
        end

        def after_letter_one_actions
          [
            Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1,
            Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1_UH,
            Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
            Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH,
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
            Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH
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

        def valid_actions_for_court_agreement_breach_letter_to_progress
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
