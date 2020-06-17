class AgreementsController < ApplicationController
  def index
    tenancy_ref = agreements_params.fetch(:tenancy_ref)

    response = income_use_case_factory.view_agreements.execute(tenancy_ref: tenancy_ref)

    render json: response
  end

  def create
    agreement_params = {
      tenancy_ref: params.fetch(:tenancy_ref),
      agreement_type: params.fetch(:agreement_type),
      amount: params.fetch(:amount),
      start_date: params.fetch(:start_date),
      frequency: params.fetch(:frequency)
    }

    response = income_use_case_factory.create_agreement.execute(new_agreement_params: agreement_params)

    render json: response
  end

  def agreements_params
    params.permit([:tenancy_ref])
  end
end
