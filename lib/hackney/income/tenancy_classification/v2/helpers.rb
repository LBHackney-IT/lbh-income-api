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

          def case_paused
            @case_priority.paused?
          end
        end
      end
    end
  end
end
