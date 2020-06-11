class AgreementsController < ApplicationController
  def index
    tenancy_ref = agreements_params.fetch(:tenancy_ref)

    response = income_use_case_factory.view_agreements.execute(tenancy_ref: tenancy_ref)

    render json: response
  end

  def agreements_params
    params.permit([:tenancy_ref])
  end
end
