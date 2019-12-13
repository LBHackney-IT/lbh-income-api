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

        def send_court_warning_letter?
          return false if @case_priority.paused?
          return false if @criteria.active_agreement?

          return false if @criteria.last_communication_action == Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT

          return false unless @criteria.nosp_served?
          return false if @criteria.nosp_served_date.blank?
          return false if @criteria.nosp_served_date > 28.days.ago.to_date

          @criteria.balance >= arrear_accumulation_by_number_weeks(4)
        end

        def apply_for_court_date?
          return false if @case_priority.paused?
          return false unless @criteria.nosp_served?

          return false unless @criteria.last_communication_action == Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT
          return false if last_communication_newer_than?(2.weeks.ago)

          return false if @criteria.nosp_served_date > 28.days.ago.to_date
          return false if @criteria.courtdate.present? && @criteria.courtdate > Time.zone.now

          @criteria.balance >= arrear_accumulation_by_number_weeks(4)
        end


        def send_sms?
          return false if @criteria.last_communication_action.present?
          return false if @criteria.nosp_served?
          return false if @case_priority.paused?
          return false if @criteria.active_agreement?

          @criteria.balance >= 5
        end

        def send_letter_one?
          return false if @case_priority.paused?
          return false if @criteria.nosp_served?
          return false if @criteria.active_agreement?

          after_letter_one_actions = [
            Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1,
            Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1_UH,
            Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
            Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH,
            Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT
          ]

          return false if @criteria.last_communication_action.in?(after_letter_one_actions) &&
                          last_communication_newer_than?(3.months.ago)

          @criteria.balance >= @criteria.weekly_rent
        end

        def send_letter_two?
          return false if @case_priority.paused?
          return false if @criteria.active_agreement?
          return false if @criteria.nosp_served?

          valid_actions = [
            Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1,
            Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1_UH
          ]

          return false unless @criteria.last_communication_action.in?(valid_actions)

          return false if last_communication_newer_than?(1.week.ago)
          return false if last_communication_older_than?(3.months.ago)

          @criteria.balance >= @criteria.weekly_rent * 3
        end

        def send_nosp?
          return false if @case_priority.paused?
          return false if @criteria.active_agreement?
          return false if @criteria.nosp_served?

          valid_actions = [
            Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
            Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH
          ]

          if @criteria.nosp_expiry_date.present?
            return false if @criteria.nosp_expiry_date >= Time.zone.now
          else
            return false unless @criteria.last_communication_action.in?(valid_actions)
            return false if last_communication_older_than?(3.months.ago)
            return false if last_communication_newer_than?(1.week.ago)
          end

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
      end
    end
  end
end
