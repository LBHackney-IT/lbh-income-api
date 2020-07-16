module Hackney
  module Income
    module TenancyClassification
      module V2
        module Helpers
          def case_paused?
            @case_priority.paused?
          end

          def case_has_eviction_date?
            @criteria.eviction_date.present?
          end

          def court_warrant_active?
            return false if @criteria.court_outcome.blank?

            if @criteria.court_outcome.in?([
              Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY,
              Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_ON_TERMS,
              Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_ON_TERMS_SECONDARY,
              Hackney::Tenancy::CourtOutcomeCodes::SUSPENDED_POSSESSION,
              Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_FORTHWITH,
              Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_WITH_DATE
            ])
              return @criteria.courtdate.blank? || @criteria.courtdate > 6.years.ago
            end

            false
          end

          def court_date_in_future?
            @criteria.courtdate.present? && @criteria.courtdate.future?
          end

          def should_prevent_action?
            case_has_eviction_date? || court_date_in_future? || case_paused?
          end

          def no_court_date?
            @criteria.courtdate.blank?
          end

          def court_outcome_missing?
            return false if court_date_in_future?
            return false if no_court_date?

            @criteria.court_outcome.blank?
          end

          def last_communication_older_than?(date)
            return false if @criteria.last_communication_date.blank?
            @criteria.last_communication_date <= date.to_date
          end

          def last_communication_newer_than?(date)
            return false if @criteria.last_communication_date.blank?
            @criteria.last_communication_date > date.to_date
          end

          def active_agreement?
            @criteria.active_agreement? || (@criteria.most_recent_agreement.present? && @criteria.most_recent_agreement[:status].in?(%i[active breached]))
          end

          def informal_breached_agreement?
            return false if should_prevent_action?
            breached_agreement? && !court_breach_agreement?
          end

          def breached_agreement?
            return false if should_prevent_action?
            return false if @criteria.most_recent_agreement.blank?
            return false if @criteria.most_recent_agreement[:start_date].blank?

            @criteria.most_recent_agreement[:breached]
          end

          def court_breach_agreement?
            return false if should_prevent_action?
            return false unless breached_agreement?
            return false if @criteria.courtdate.blank?

            @criteria.most_recent_agreement[:start_date] > @criteria.courtdate
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
            @criteria.balance - calculated_grace_amount
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
end
