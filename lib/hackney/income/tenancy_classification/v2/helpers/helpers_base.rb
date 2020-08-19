module Hackney
  module Income
    module TenancyClassification
      module V2
        module Helpers
          module HelpersBase
            def most_recent_agreement
              @most_recent_agreement ||= Hackney::Income::Models::Agreement.where(tenancy_ref: @criteria.tenancy_ref).last
            end

            def most_recent_court_case
              @most_recent_court_case ||= Hackney::Income::Models::CourtCase.where(tenancy_ref: @criteria.tenancy_ref).last
            end
          end
        end
      end
    end
  end
end
