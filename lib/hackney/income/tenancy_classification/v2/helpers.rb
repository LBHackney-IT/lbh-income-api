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

          def court_date_in_future?
            @criteria.courtdate.present? && @criteria.courtdate.future?
          end

          def should_prevent_action?
            case_has_eviction_date? || court_date_in_future? || case_paused?
          end

          def no_court_date?
            @criteria.courtdate.blank?
          end

          def last_communication_older_than?(date)
            return false if @criteria.last_communication_date.blank?
            @criteria.last_communication_date <= date.to_date
          end

          def last_communication_newer_than?(date)
            return false if @criteria.last_communication_date.blank?
            @criteria.last_communication_date > date.to_date
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
        end
      end
    end
  end
end
