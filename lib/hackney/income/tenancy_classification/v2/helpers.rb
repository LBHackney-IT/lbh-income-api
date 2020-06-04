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

          def last_communication_older_than?(date)
            return false if @criteria.last_communication_date.blank?
            @criteria.last_communication_date <= date.to_date
          end

          def last_communication_newer_than?(date)
            return false if @criteria.last_communication_date.blank?
            @criteria.last_communication_date > date.to_date
          end
        end
      end
    end
  end
end
