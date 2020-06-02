module Hackney
  module Income
    module TenancyClassification
      module V2
        module Rulesets
          class ReviewFailedLetter
            def self.valid?(case_priority, criteria, documents)
              return nil if documents.empty?
              return :review_failed_letter if documents.most_recent.failed? && documents.most_recent.income_collection?
            end
          end
        end
      end
    end
  end
end
