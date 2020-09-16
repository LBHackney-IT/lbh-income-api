module Hackney
  module Income
    module TenancyClassification
      module Rulesets
        class BaseRuleset
          include Helpers

          def initialize(case_priority, criteria, documents)
            @case_priority = case_priority
            @criteria = criteria
            @documents = documents
          end
        end
      end
    end
  end
end
