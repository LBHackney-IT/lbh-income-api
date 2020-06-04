module Hackney
  module Income
    module TenancyClassification
      module V2
        module Rulesets
          class ReviewFailedLetter
            class << self
              def execute(helpers, case_priority, criteria, documents)
                return :review_failed_letter if action_valid(case_priority, criteria, documents)
              end

              private

              def action_valid(case_priority, criteria, documents)
                return false if documents.empty?

                documents.most_recent.failed? && documents.most_recent.income_collection?
              end
            end
          end
        end
      end
    end
  end
end
