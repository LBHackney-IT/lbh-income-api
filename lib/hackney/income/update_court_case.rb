module Hackney
  module Income
    class UpdateCourtCase
      def execute(court_case_params:)
        court_case_id = court_case_params[:id]
        court_case = Hackney::Income::Models::CourtCase.find_by_id(court_case_id)

        return if court_case.nil?

        params = {
          court_date: court_case_params[:court_date],
          court_outcome: court_case_params[:court_outcome],
          balance_on_court_outcome_date: court_case_params[:balance_on_court_outcome_date],
          strike_out_date: court_case_params[:strike_out_date],
          terms: court_case_params[:terms],
          disrepair_counter_claim: court_case_params[:disrepair_counter_claim]
        }.reject { |_key, value| value.nil? }

        court_case.update(params)
        court_case
      end
    end
  end
end
