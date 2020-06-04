module Hackney
  module Income
    module TenancyClassification
      module V2
        module Rulesets
          class BaseRuleset
            include V2::Helpers

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
end
