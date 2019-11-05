require "#{Rails.root}/lib/hackney/service_charge/exceptions/service_charge_exception"

class LettersController < ApplicationController
  def get_templates
    render json: pdf_use_case_factory.get_templates.execute
  end

  def create
    render json: pdf_use_case_factory.get_preview.execute(
      payment_ref: params.fetch(:payment_ref),
      template_id: params.fetch(:template_id)
    )
  rescue Hackney::Income::TenancyNotFoundError
    head(404)
  end

  def send_letter
    income_use_case_factory.send_letter.execute(
      uuid: params.fetch(:uuid),
      username: params.fetch(:username),
      email: params.fetch(:email)
    )
  end
end
