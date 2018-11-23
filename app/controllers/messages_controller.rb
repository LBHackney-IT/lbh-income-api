class MessagesController < ApplicationController
  def send_sms
    income_use_case_factory.send_sms.execute(
      user_id: params.fetch(:user_id),
      tenancy_ref: params.fetch(:tenancy_ref),
      template_id: params.fetch(:template_id),
      phone_number: params.fetch(:phone_number),
      reference: params.fetch(:reference),
      variables: params.fetch(:variables)
    )
  end

  def send_email
    income_use_case_factory.send_email.execute(
      user_id: params.fetch(:user_id),
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
