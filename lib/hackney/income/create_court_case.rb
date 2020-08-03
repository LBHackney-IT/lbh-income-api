module Hackney
  module Income
    class CreateCourtCase
      def execute(court_case_params:)
        params = {
          tenancy_ref: court_case_params[:tenancy_ref],
          date_of_court_decision: court_case_params[:date_of_court_decision],
          court_outcome: court_case_params[:court_outcome],
          balance_on_court_outcome_date: court_case_params[:balance_on_court_outcome_date],
          strike_out_date: court_case_params[:strike_out_date],
          created_by: court_case_params[:created_by]
        }

        court_case = Hackney::Income::Models::CourtCase.create!(params)
        court_case
      end
    end
  end
end
