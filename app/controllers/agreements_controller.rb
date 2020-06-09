class AgreementsController < ApplicationController
  def index
    tenancy_ref = agreements_params.fetch(:tenancy_ref)

    response = Hackney::Income::ViewAgreements.execute(tenancy_ref: tenancy_ref)

    render json: response
  end

  def agreements_params
    params.permit([:tenancy_ref])
  end
end
