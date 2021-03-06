class AgreementsController < ApplicationController
  include AgreementResponseHelper

  def index
    tenancy_ref = agreements_params.fetch(:tenancy_ref)

    requested_agreements = income_use_case_factory.view_agreements.execute(tenancy_ref: tenancy_ref)

    agreements = requested_agreements.map do |agreement|
      map_agreement_to_response(agreement: agreement)
    end

    response = { agreements: agreements }
    render json: response
  end

  def create
    agreement_params = {
      tenancy_ref: params.fetch(:tenancy_ref),
      agreement_type: params.fetch(:agreement_type),
      amount: params.fetch(:amount),
      start_date: params.fetch(:start_date),
      frequency: params.fetch(:frequency).to_sym,
      created_by: params.fetch(:created_by),
      notes: params.fetch(:notes),
      court_case_id: params.dig(:court_case_id),
      initial_payment_amount: params.dig(:initial_payment_amount),
      initial_payment_date: params.dig(:initial_payment_date)
    }

    if formal_agreement?(agreement_params)
      created_agreement = income_use_case_factory.create_formal_agreement.execute(new_agreement_params: agreement_params)
    else
      created_agreement = income_use_case_factory.create_informal_agreement.execute(new_agreement_params: agreement_params)
    end

    response = map_agreement_to_response(agreement: created_agreement)
    render json: response
  end

  def cancel
    cancelled_agreement = income_use_case_factory.cancel_agreement.execute(
      agreement_id: params.fetch(:agreement_id),
      cancelled_by: params.fetch(:cancelled_by),
      cancellation_reason: params.fetch(:cancellation_reason)
    )
    if cancelled_agreement
      response = map_agreement_to_response(agreement: cancelled_agreement)
      render json: response
    else
      render json: { error: 'agreement not found' }, status: :not_found
    end
  end

  def agreements_params
    params.permit([:tenancy_ref])
  end

  def formal_agreement?(params)
    params[:agreement_type] == 'formal' && params[:court_case_id].present?
  end
end
