class MessagesController < ApplicationController
  def send_sms
    income_use_case_factory.send_manual_sms.execute(
      username: params.fetch(:username),
      tenancy_ref: params.fetch(:tenancy_ref),
      template_id: params.fetch(:template_id),
      phone_number: params.fetch(:phone_number),
      reference: params.fetch(:reference),
      variables: params.fetch(:variables)
    )
  rescue ArgumentError => e
    render(json: { status: 'error', code: 422, message: e.message }, status: :unprocessable_entity)
    nil
  end

  def send_email
    income_use_case_factory.send_manual_email.execute(
      username: params.fetch(:username),
      tenancy_ref: params.fetch(:tenancy_ref),
      template_id: params.fetch(:template_id),
      recipient: params.fetch(:email_address),
      reference: params.fetch(:reference),
      variables: params.fetch(:variables)
    )
  end

  def get_templates
    render json: income_use_case_factory.get_templates.execute(
      type: params.fetch(:type)
    )
  end
end
