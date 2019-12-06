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
          return if Hackney::Income::Models::CasePriority.classifications.key?(wanted_action)
          raise ArgumentError, "Tried to classify a case as #{wanted_action}, but this is not on the list of valid classifications."
        end

        def send_court_warning_letter?
          return false if @criteria.nosp_served_date.blank?

          @criteria.last_communication_action != Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT &&
            @criteria.nosp_served? &&
            @criteria.nosp_served_date <= 28.days.ago.to_date &&
            @criteria.balance >= arrear_accumulation_by_number_weeks(4) &&
            @case_priority.paused? == false &&
            @criteria.active_agreement? == false
        end

        def apply_for_court_date?
          valid_actions = [
            Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT
          ]

          can_apply_for_court_date =
            @criteria.last_communication_action.in?(valid_actions) &&
            last_communication_date_before?(2.weeks.ago) &&
            @criteria.balance >= arrear_accumulation_by_number_weeks(4) &&
            @criteria.nosp_served? == true &&
            @criteria.nosp_served_date <= 28.days.ago.to_date &&
            @case_priority.paused? == false

          can_apply_for_court_date &&= @criteria.courtdate <= Time.zone.now if @criteria.courtdate.present?

          can_apply_for_court_date
        end

        def send_sms?
          @criteria.last_communication_action.nil? &&
            @criteria.balance >= 5 &&
            @criteria.nosp_served? == false &&
            last_communication_between_three_months_one_week? &&
            @case_priority.paused? == false &&
            @criteria.active_agreement? == false
        end

        def send_letter_one?
          future_communication_actions = [
            Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
            Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH,
            Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT,
            Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1
          ]
          can_send_letter_one = false
          if @criteria.balance >= @criteria.weekly_rent &&
             @criteria.balance < arrear_accumulation_by_number_weeks(3) &&
             @criteria.nosp_served? == false &&
             last_communication_between_three_months_one_week? &&
             @case_priority.paused? == false &&
             @criteria.active_agreement? == false
            can_send_letter_one = true
          end
          can_send_letter_one = @criteria.last_communication_date < 3.months.ago if @criteria.last_communication_action.in?(future_communication_actions)
          can_send_letter_one
        end

        def send_letter_two?
          valid_actions = [
            Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1
          ]

          @criteria.last_communication_action.in?(valid_actions) &&
            @criteria.balance >= arrear_accumulation_by_number_weeks(3) &&
            @criteria.nosp_served? == false &&
            last_communication_between_three_months_one_week? &&
            @case_priority.paused? == false
        end

        def send_nosp?
          valid_actions = [
            Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
            Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH
          ]

          can_send_nosp = false

          if @criteria.nosp_expiry_date.present?
            can_send_nosp = @criteria.nosp_expiry_date < Time.zone.now
          elsif @criteria.active_agreement?
            can_send_nosp = false
          else
            can_send_nosp = @criteria.last_communication_action.in?(valid_actions) &&
                            last_communication_between_three_months_one_week?
          end

          can_send_nosp && @criteria.nosp_served? == false &&
            @criteria.balance >= arrear_accumulation_by_number_weeks(4) &&
            @case_priority.paused? == false
        end

        def last_communication_between_three_months_one_week?
          return false if @criteria.last_communication_date.nil?

          last_communication_date_before?(1.week.ago) && last_communication_date_after?(3.months.ago)
        end

        def last_communication_date_before?(date)
          @criteria.last_communication_date <= date.to_date
        end

        def last_communication_date_after?(date)
          @criteria.last_communication_date >= date.to_date
        end

        def arrear_accumulation_by_number_weeks(weeks)
          @criteria.weekly_rent * weeks
        end
      end
    end
  end
end
