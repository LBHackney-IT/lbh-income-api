class CourtCasesController < ApplicationController
  include CourtCaseResponseHelper

  def index
    requested_cases = income_use_case_factory.view_court_cases.execute(tenancy_ref: params.fetch(:tenancy_ref))

    cases = requested_cases.map do |c|
      map_court_case_to_response(court_case: c)
    end

    response = { court_cases: cases }
    render json: response
  end

  def create
    court_case_params = {
      tenancy_ref: params.fetch(:tenancy_ref),
      date_of_court_decision: params.fetch(:date_of_court_decision),
      court_outcome: params.fetch(:court_outcome),
      balance_on_court_outcome_date: params.fetch(:balance_on_court_outcome_date),
      strike_out_date: params.fetch(:strike_out_date),
      created_by: params.fetch(:created_by)
    }

    new_court_case = income_use_case_factory.create_court_case.execute(court_case_params: court_case_params)
    response = map_court_case_to_response(court_case: new_court_case)

    render json: response
  end
end
