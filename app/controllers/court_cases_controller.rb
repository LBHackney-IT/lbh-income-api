class CourtCasesController < ApplicationController
  include CourtCaseResponseHelper
  REQUIRED_UPDATE_PARAMS = %i[id tenancy_ref court_date court_outcome balance_on_court_outcome_date].freeze
  OPTIONAL_UPDATE_PARAMS = %i[strike_out_date terms disrepair_counter_claim].freeze

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
      id: update_court_case_params[:id],
      tenancy_ref: update_court_case_params[:tenancy_ref],
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

  def update_court_case_params
    params.require(REQUIRED_UPDATE_PARAMS)
    params.permit(REQUIRED_UPDATE_PARAMS + OPTIONAL_UPDATE_PARAMS)
  end
end
