module Hackney
  module Income
    module TenancyClassification
      module V2
        module Rulesets
          class BaseRuleset
            include V2::Helpers

            def initialize(case_priority, criteria, documents, contact_numbers)
              @case_priority = case_priority
              @criteria = criteria
              @documents = documents
              @contact_numbers = contact_numbers
            end
          end
        end
      end
    end
  end
end
