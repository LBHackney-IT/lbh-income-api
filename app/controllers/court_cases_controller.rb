class CourtCasesController < ApplicationController
  include CourtCaseResponseHelper
  def index
    requested_cases = income_use_case_factory.view_court_cases.execute(tenancy_ref: params.fetch(:tenancy_ref))

    cases = requested_cases.map do |c|
      map_court_case_to_response(court_case: c)
    end

    response = { courtCases: cases }
    render json: response
  end

  def create
    parameters = %i[tenancy_ref court_date court_outcome balance_on_court_outcome_date strike_out_date terms disrepair_counter_claim username].freeze

    create_court_case_params = params.permit(parameters)

    court_case_params = {
      tenancy_ref: create_court_case_params[:tenancy_ref],
      court_date: create_court_case_params[:court_date],
      court_outcome: create_court_case_params[:court_outcome],
      balance_on_court_outcome_date: create_court_case_params[:balance_on_court_outcome_date],
      strike_out_date: create_court_case_params[:strike_out_date],
      terms: create_court_case_params[:terms],
      disrepair_counter_claim: create_court_case_params[:disrepair_counter_claim]
    }

    new_court_case = income_use_case_factory.create_court_case_and_sync.execute(court_case_params: court_case_params, username: create_court_case_params[:username])
    response = map_court_case_to_response(court_case: new_court_case)

    render json: response
  end

  def update
    parameters = %i[id court_date court_outcome balance_on_court_outcome_date strike_out_date terms disrepair_counter_claim].freeze

    update_court_case_params = params.permit(parameters)

    court_case_params = {
      id: update_court_case_params[:id],
      court_date: update_court_case_params[:court_date],
      court_outcome: update_court_case_params[:court_outcome],
      balance_on_court_outcome_date: update_court_case_params[:balance_on_court_outcome_date],
      strike_out_date: update_court_case_params[:strike_out_date],
      terms: update_court_case_params[:terms],
      disrepair_counter_claim: update_court_case_params[:disrepair_counter_claim]
    }

    updated_court_case = income_use_case_factory.update_court_case.execute(court_case_params: court_case_params)

    if updated_court_case
      response = map_court_case_to_response(court_case: updated_court_case)
      render json: response
    else
      render json: { error: 'court case not found' }, status: :not_found
    end
  end
end
