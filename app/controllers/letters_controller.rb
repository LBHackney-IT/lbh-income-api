require "#{Rails.root}/lib/hackney/service_charge/exceptions/service_charge_exception"
require 'hackney/income/universal_housing_leasehold_gateway.rb'

class LettersController < ApplicationController
  def get_templates
    render json: pdf_use_case_factory.get_templates.execute
  end

  def create
    json = generate_and_store_use_case.execute(
      payment_ref: parms_for_generate_and_store[:payment_ref],
      template_id: parms_for_generate_and_store[:template_id],
      user_id: parms_for_generate_and_store[:user_id]
    )

    render json: json
  rescue Hackney::Income::TenancyNotFoundError
    head(404)
  end

  def send_letter
    document_model = Hackney::Cloud::Document.find_by!(uuid: params[:uuid])
    Hackney::Income::Jobs::SendLetterToGovNotifyJob.perform_later(document_id: document_model.id)
  end

  private

  def parms_for_generate_and_store
    params.permit(%i[user_id payment_ref template_id])
  end

  def generate_and_store_use_case
    UseCases::GenerateAndStoreLetter.new
  end
end
