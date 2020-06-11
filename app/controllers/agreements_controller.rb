class AgreementsController < ApplicationController
  def index
    tenancy_ref = agreements_params.fetch(:tenancy_ref)

    response = income_use_case_factory.view_agreements.execute(tenancy_ref: tenancy_ref)

    render json: response
  end

  def create
    tenancy_ref = params.fetch(:tenancy_ref)

    agreement_params = {
      tenancy_ref: params.fetch(:tenancy_ref),
      agreement_type: params.fetch(:agreement_type),
      # TODO: starting_balance: starting_balance,
      amount: params.fetch(:amount),
      start_date: params.fetch(:start_date),
      frequency: params.fetch(:frequency),
      current_state: 'active'
    }

    Hackney::Income::Models::Agreement.create!(agreement_params)
    new_agreement = income_use_case_factory.view_agreements.execute(tenancy_ref: tenancy_ref)[:agreements].first

    response = new_agreement

    render json: response
  end

  def agreements_params
    params.permit([:tenancy_ref])
  end
end
