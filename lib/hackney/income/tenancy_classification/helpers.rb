module Hackney
  module Income
    module TenancyClassification
      module Helpers
        include Hackney::Income::TenancyClassification::Helpers::AgreementHelpers
        include Hackney::Income::TenancyClassification::Helpers::CourtCaseHelpers

        def case_paused?
          @case_priority.paused?
        end

        def case_has_eviction_date?
          eviction_date.present?
        end

        def should_prevent_action?
          case_has_eviction_date? || court_date_in_future? || case_paused?
        end

        def last_communication_older_than?(date)
          return false if @criteria.last_communication_date.blank?
          @criteria.last_communication_date <= date.to_date
        end

        def last_communication_newer_than?(date)
          return false if @criteria.last_communication_date.blank?
          @criteria.last_communication_date > date.to_date
        end

        def balance_is_in_arrears_by_number_of_weeks?(weeks)
          balance_with_1_week_grace >= arrear_accumulation_by_number_weeks(weeks)
        end

        def arrear_accumulation_by_number_weeks(weeks)
          @criteria.weekly_gross_rent * weeks
        end

        def balance_is_in_arrears_by_amount?(amount)
          balance_with_1_week_grace >= amount
        end

        def balance_with_1_week_grace
          @criteria.collectable_arrears - calculated_grace_amount
        end

        def calculated_grace_amount
          grace_amount = @criteria.weekly_gross_rent + @criteria.total_payment_amount_in_week

          return 0 if grace_amount.negative?

          grace_amount
        end
      end
    end
  end
end
