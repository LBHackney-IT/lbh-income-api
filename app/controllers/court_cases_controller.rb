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
      tenancy_ref: params.require(:tenancy_ref),
      court_date: params.require(:court_date)
    }

    new_court_case = income_use_case_factory.create_court_case.execute(court_case_params: court_case_params)
    response = map_court_case_to_response(court_case: new_court_case)

    render json: response
  end

  def update
    court_case_params = {
      id: params.require(:id),
      tenancy_ref: params.require(:tenancy_ref),
      court_date: params.require(:court_date),
      court_outcome: params.require(:court_outcome),
      balance_on_court_outcome_date: params.require(:balance_on_court_outcome_date)
    }

    updated_court_case = income_use_case_factory.update_court_case.execute(court_case_params: court_case_params)
    response = map_court_case_to_response(court_case: updated_court_case)

    render json: response
  end
end
