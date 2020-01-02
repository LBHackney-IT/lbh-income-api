module Hackney
  module Income
    class TenancyPrioritiser
      class TenancyClassification
        def initialize(case_priority, criteria)
          @criteria = criteria
          @case_priority = case_priority
        end

        def execute
          wanted_action = nil

          wanted_action ||= :no_action if @criteria.eviction_date.present?
          wanted_action ||= :no_action if @criteria.courtdate.present? && @criteria.courtdate >= Time.zone.now
          wanted_action ||= :no_action if @case_priority.paused?

          wanted_action ||= :send_court_agreement_breach_letter if send_court_agreement_breach_letter?
          wanted_action ||= :send_informal_agreement_breach_letter if send_informal_agreement_breach_letter?
          wanted_action ||= :apply_for_court_date if apply_for_court_date?
          wanted_action ||= :send_court_warning_letter if send_court_warning_letter?
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

        def send_informal_agreement_breach_letter?
          return false if @criteria.number_of_broken_agreements < 1
          return false if @criteria.active_agreement? == true
          return false if @criteria.balance >= @criteria.expected_balance
          return false if @criteria.courtdate.present? && @criteria.courtdate < Date.today
          return false if @criteria.breach_agreement_date + 3.days > Date.today
          return false unless @criteria.last_communication_action.in?(valid_actions_for_court_agreement_breach_letter_to_progress)
          true
        end

        def send_court_agreement_breach_letter?
          return false if @criteria.number_of_broken_agreements < 1
          return false if @criteria.active_agreement? == true
          return false if @criteria.latest_active_agreement_date.blank?
          return false if @criteria.courtdate.blank?
          return false if @criteria.latest_active_agreement_date <= @criteria.courtdate
          return false if @criteria.breach_agreement_date + 3.days > Date.today
          return false if @criteria.balance >= @criteria.expected_balance
          return false unless @criteria.court_outcome == 'AGR'
          return false unless @criteria.last_communication_action.in?(valid_actions_for_court_agreement_breach_letter_to_progress)
          true
        end

        def send_sms?
          return false if @criteria.last_communication_action.present?
          return false if @criteria.nosp_served?
          return false if @criteria.active_agreement?

          @criteria.balance >= 5
        end

        def send_letter_one?
          return false if @criteria.nosp_served?
          return false if @criteria.active_agreement?

          return false if @criteria.last_communication_action.in?(after_letter_one_actions) &&
                          last_communication_newer_than?(3.months.ago)

          @criteria.balance >= arrear_accumulation_by_number_weeks(1)
        end

        def send_letter_two?
          return false if @criteria.active_agreement?
          return false if @criteria.nosp_served?

          return false unless @criteria.last_communication_action.in?(valid_actions_for_letter_two_to_progress)

          return false if last_communication_newer_than?(1.week.ago)
          return false if last_communication_older_than?(3.months.ago)

          @criteria.balance >= arrear_accumulation_by_number_weeks(3)
        end

        def send_nosp?
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
          return false if @criteria.active_agreement?

          return false if @criteria.last_communication_action.in?(after_court_warning_letter_actions)

          return false unless @criteria.nosp_served?
          return false if @criteria.nosp_served_date.blank?
          return false if @criteria.nosp_served_date > 28.days.ago.to_date

          @criteria.balance >= arrear_accumulation_by_number_weeks(4)
        end

        def apply_for_court_date?
          return false unless @criteria.nosp_served?

          return false unless @criteria.last_communication_action.in?(valid_actions_for_apply_for_court_date_to_progress)
          return false if last_communication_newer_than?(2.weeks.ago)

          return false if @criteria.nosp_served_date > 28.days.ago.to_date

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
      end
    end
  end
end
