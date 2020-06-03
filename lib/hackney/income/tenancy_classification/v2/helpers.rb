module Hackney
  module Income
    module TenancyClassification
      module V2
        class Helpers
          def initialize(case_priority, criteria, documents)
            @criteria = criteria
            @case_priority = case_priority
            @documents = documents
          end

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
        end
      end
    end
  end
end
