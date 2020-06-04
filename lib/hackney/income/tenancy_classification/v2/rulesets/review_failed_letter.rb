module Hackney
  module Income
    module TenancyClassification
      module V2
        module Rulesets
          class ReviewFailedLetter < BaseRuleset
            def execute
              return :review_failed_letter if action_valid
            end

            private

            def action_valid
              return false if @documents.empty?

              @documents.most_recent.failed? && @documents.most_recent.income_collection?
            end
          end
        end
      end
    end
  end
end
