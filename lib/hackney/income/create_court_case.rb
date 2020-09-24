module Hackney
  module Income
    class CreateCourtCase
      def initialize(add_action_diary_and_sync_case:)
        @add_action_diary_and_sync_case = add_action_diary_and_sync_case
      end

      def execute(court_case_params:)
        params = {
          tenancy_ref: court_case_params[:tenancy_ref],
          court_date: court_case_params[:court_date],
          court_outcome: court_case_params[:court_outcome],
          balance_on_court_outcome_date: court_case_params[:balance_on_court_outcome_date],
          strike_out_date: court_case_params[:strike_out_date],
          terms: court_case_params[:terms],
          disrepair_counter_claim: court_case_params[:disrepair_counter_claim]
        }

        court_case = Hackney::Income::Models::CourtCase.create!(params)

        @add_action_diary_and_sync_case.execute(
          tenancy_ref: court_case_params[:tenancy_ref],
          action_code: Hackney::Tenancy::ActionCodes::COURT_DATE_SET,
          comment: 'Court case created',
          username: court_case_params[:username]
        )

        court_case
      end
    end
  end
end
