module Hackney
  module Income
    module TenancyClassification
      module Rulesets
        class BaseRuleset
          include Helpers

          def initialize(case_priority, criteria, documents, use_ma_data = true)
            @case_priority = case_priority
            @criteria = criteria
            @documents = documents
            @use_ma_data = use_ma_data
          end
        end
      end
    end
  end
end
